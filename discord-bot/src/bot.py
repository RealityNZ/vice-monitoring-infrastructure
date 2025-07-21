#!/usr/bin/env python3
"""
Vice Infrastructure Discord Bot
Monitors infrastructure and provides metrics via Discord
"""

import asyncio
import logging
import os
import yaml
import discord
from discord.ext import commands
from prometheus_client import start_http_server, Counter, Gauge, Histogram, Summary
import psutil
import time
from datetime import datetime, timedelta
import aiohttp
import json

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Prometheus metrics
MESSAGES_PROCESSED = Counter('discord_messages_processed_total', 'Total messages processed')
COMMANDS_EXECUTED = Counter('discord_commands_executed_total', 'Total commands executed', ['command'])
ERRORS_TOTAL = Counter('discord_errors_total', 'Total errors', ['type'])
RESPONSE_TIME = Histogram('discord_response_time_seconds', 'Response time in seconds')
GUILD_COUNT = Gauge('discord_guild_count', 'Number of guilds')
USER_COUNT = Gauge('discord_user_count', 'Number of users')
CHANNEL_COUNT = Gauge('discord_channel_count', 'Number of channels')
BOT_UPTIME = Gauge('discord_bot_uptime_seconds', 'Bot uptime in seconds')
MESSAGE_QUEUE_SIZE = Gauge('discord_message_queue_size', 'Message queue size')
CONNECTION_STATUS = Gauge('discord_bot_connection_status', 'Bot connection status')

class ViceMonitoringBot(commands.Bot):
    def __init__(self, config_path='config.yml'):
        self.config = self.load_config(config_path)
        self.start_time = time.time()
        self.message_queue = asyncio.Queue()
        self.connection_status = 0
        
        # Initialize bot with intents
        intents = discord.Intents.default()
        intents.message_content = True
        intents.guilds = True
        intents.members = True
        
        super().__init__(
            command_prefix=self.config['discord']['prefix'],
            intents=intents,
            help_command=None
        )
        
        # Start Prometheus metrics server
        if self.config['prometheus']['enabled']:
            start_http_server(
                self.config['prometheus']['port'],
                addr='0.0.0.0'
            )
            logger.info(f"Prometheus metrics server started on port {self.config['prometheus']['port']}")
    
    def load_config(self, config_path):
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r') as file:
                config = yaml.safe_load(file)
            
            # Replace environment variables
            for key, value in os.environ.items():
                if isinstance(value, str):
                    config_str = yaml.dump(config)
                    config_str = config_str.replace(f'${{{key}}}', value)
                    config = yaml.safe_load(config_str)
            
            return config
        except Exception as e:
            logger.error(f"Failed to load config: {e}")
            return {}
    
    async def setup_hook(self):
        """Setup bot hooks and commands"""
        await self.add_cog(MonitoringCommands(self))
        await self.add_cog(AdminCommands(self))
        await self.add_cog(LogCollection(self))
        
        # Start background tasks
        self.bg_task = self.loop.create_task(self.background_tasks())
    
    async def on_ready(self):
        """Called when bot is ready"""
        logger.info(f'{self.user} has connected to Discord!')
        self.connection_status = 1
        CONNECTION_STATUS.set(1)
        
        # Update metrics
        GUILD_COUNT.set(len(self.guilds))
        USER_COUNT.set(sum(len(guild.members) for guild in self.guilds))
        CHANNEL_COUNT.set(sum(len(guild.channels) for guild in self.guilds))
        
        # Set bot status
        await self.change_presence(
            activity=discord.Activity(
                type=discord.ActivityType.watching,
                name="Vice Infrastructure"
            )
        )
    
    async def on_message(self, message):
        """Handle incoming messages"""
        if message.author == self.user:
            return
        
        MESSAGES_PROCESSED.inc()
        
        # Process commands
        await self.process_commands(message)
        
        # Add to message queue for log collection
        if self.config['monitoring']['log_collection']['enabled']:
            await self.message_queue.put({
                'timestamp': datetime.now().isoformat(),
                'author': str(message.author),
                'content': message.content,
                'channel': str(message.channel),
                'guild': str(message.guild)
            })
    
    async def on_command_error(self, ctx, error):
        """Handle command errors"""
        if isinstance(error, commands.CommandNotFound):
            return
        
        ERRORS_TOTAL.labels(type='command').inc()
        logger.error(f"Command error: {error}")
        
        embed = discord.Embed(
            title="Error",
            description=f"An error occurred: {str(error)}",
            color=discord.Color.red()
        )
        await ctx.send(embed=embed)
    
    async def background_tasks(self):
        """Background tasks for metrics collection"""
        while True:
            try:
                # Update uptime
                uptime = time.time() - self.start_time
                BOT_UPTIME.set(uptime)
                
                # Update queue size
                MESSAGE_QUEUE_SIZE.set(self.message_queue.qsize())
                
                # Update guild/user/channel counts
                GUILD_COUNT.set(len(self.guilds))
                USER_COUNT.set(sum(len(guild.members) for guild in self.guilds))
                CHANNEL_COUNT.set(sum(len(guild.channels) for guild in self.guilds))
                
                await asyncio.sleep(self.config['monitoring']['metrics_interval'])
                
            except Exception as e:
                logger.error(f"Background task error: {e}")
                ERRORS_TOTAL.labels(type='background').inc()
                await asyncio.sleep(60)

class MonitoringCommands(commands.Cog):
    def __init__(self, bot):
        self.bot = bot
    
    @commands.command(name='status')
    async def status(self, ctx):
        """Show system status"""
        start_time = time.time()
        
        try:
            # Get system metrics
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            # Get bot metrics
            uptime = time.time() - self.bot.start_time
            guild_count = len(self.bot.guilds)
            user_count = sum(len(guild.members) for guild in self.bot.guilds)
            
            embed = discord.Embed(
                title="🖥️ Vice Infrastructure Status",
                color=discord.Color.green(),
                timestamp=datetime.now()
            )
            
            embed.add_field(
                name="System",
                value=f"CPU: {cpu_percent}%\nMemory: {memory.percent}%\nDisk: {disk.percent}%",
                inline=True
            )
            
            embed.add_field(
                name="Bot",
                value=f"Uptime: {timedelta(seconds=int(uptime))}\nGuilds: {guild_count}\nUsers: {user_count}",
                inline=True
            )
            
            embed.add_field(
                name="Connection",
                value=f"Status: {'🟢 Online' if self.bot.connection_status else '🔴 Offline'}\nLatency: {round(self.bot.latency * 1000)}ms",
                inline=True
            )
            
            await ctx.send(embed=embed)
            
            # Record metrics
            COMMANDS_EXECUTED.labels(command='status').inc()
            response_time = time.time() - start_time
            RESPONSE_TIME.observe(response_time)
            
        except Exception as e:
            logger.error(f"Status command error: {e}")
            ERRORS_TOTAL.labels(type='status_command').inc()
            await ctx.send("❌ Error getting status")
    
    @commands.command(name='metrics')
    async def metrics(self, ctx):
        """Show current metrics"""
        start_time = time.time()
        
        try:
            # Get Prometheus metrics
            async with aiohttp.ClientSession() as session:
                async with session.get(f"http://localhost:{self.bot.config['prometheus']['port']}/metrics") as response:
                    if response.status == 200:
                        metrics_text = await response.text()
                        
                        # Create a summary of key metrics
                        embed = discord.Embed(
                            title="📊 Current Metrics",
                            description="Key monitoring metrics",
                            color=discord.Color.blue(),
                            timestamp=datetime.now()
                        )
                        
                        # Parse some key metrics
                        lines = metrics_text.split('\n')
                        for line in lines:
                            if 'discord_messages_processed_total' in line:
                                messages = line.split()[-1]
                                embed.add_field(name="Messages Processed", value=messages, inline=True)
                            elif 'discord_commands_executed_total' in line:
                                commands = line.split()[-1]
                                embed.add_field(name="Commands Executed", value=commands, inline=True)
                            elif 'discord_errors_total' in line:
                                errors = line.split()[-1]
                                embed.add_field(name="Total Errors", value=errors, inline=True)
                        
                        await ctx.send(embed=embed)
                    else:
                        await ctx.send("❌ Unable to fetch metrics")
            
            COMMANDS_EXECUTED.labels(command='metrics').inc()
            response_time = time.time() - start_time
            RESPONSE_TIME.observe(response_time)
            
        except Exception as e:
            logger.error(f"Metrics command error: {e}")
            ERRORS_TOTAL.labels(type='metrics_command').inc()
            await ctx.send("❌ Error getting metrics")

class AdminCommands(commands.Cog):
    def __init__(self, bot):
        self.bot = bot
    
    def is_admin(ctx):
        """Check if user has admin role"""
        if not ctx.guild:
            return False
        
        admin_roles = ctx.bot.config['security']['admin_roles']
        user_roles = [role.name for role in ctx.author.roles]
        
        return any(role in user_roles for role in admin_roles)
    
    @commands.command(name='restart')
    @commands.check(is_admin)
    async def restart(self, ctx):
        """Restart monitoring services (Admin only)"""
        embed = discord.Embed(
            title="🔄 Restarting Services",
            description="Restarting monitoring services...",
            color=discord.Color.yellow()
        )
        await ctx.send(embed=embed)
        
        # Here you would implement actual service restart logic
        # For now, just log the action
        logger.info(f"Restart requested by {ctx.author}")
        COMMANDS_EXECUTED.labels(command='restart').inc()
    
    @commands.command(name='backup')
    @commands.check(is_admin)
    async def backup(self, ctx):
        """Create backup (Admin only)"""
        embed = discord.Embed(
            title="💾 Creating Backup",
            description="Creating system backup...",
            color=discord.Color.blue()
        )
        await ctx.send(embed=embed)
        
        # Here you would implement actual backup logic
        logger.info(f"Backup requested by {ctx.author}")
        COMMANDS_EXECUTED.labels(command='backup').inc()

class LogCollection(commands.Cog):
    def __init__(self, bot):
        self.bot = bot
    
    @commands.command(name='logs')
    async def logs(self, ctx, limit: int = 10):
        """Show recent logs"""
        if limit > 50:
            limit = 50
        
        logs = []
        for _ in range(min(limit, self.bot.message_queue.qsize())):
            try:
                log_entry = self.bot.message_queue.get_nowait()
                logs.append(log_entry)
            except asyncio.QueueEmpty:
                break
        
        if not logs:
            await ctx.send("No recent logs available")
            return
        
        embed = discord.Embed(
            title="📝 Recent Logs",
            description=f"Last {len(logs)} messages",
            color=discord.Color.greyple(),
            timestamp=datetime.now()
        )
        
        for log in logs[-5:]:  # Show last 5 logs
            embed.add_field(
                name=f"{log['timestamp'][:19]} - {log['author']}",
                value=f"**{log['channel']}**: {log['content'][:100]}...",
                inline=False
            )
        
        await ctx.send(embed=embed)
        COMMANDS_EXECUTED.labels(command='logs').inc()

async def main():
    """Main function"""
    bot = ViceMonitoringBot()
    
    try:
        await bot.start(bot.config['discord']['token'])
    except KeyboardInterrupt:
        logger.info("Bot shutdown requested")
    except Exception as e:
        logger.error(f"Bot error: {e}")
    finally:
        await bot.close()

if __name__ == "__main__":
    asyncio.run(main()) 