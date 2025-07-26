#!/usr/bin/env python3
"""
VICE Discord Bot with Prometheus Metrics
"""

import os
import yaml
import logging
import asyncio
import discord
from discord.ext import commands
from prometheus_client import start_http_server, Counter, Histogram, Gauge
import psutil
import time

# Prometheus metrics
COMMAND_COUNTER = Counter('discord_commands_total', 'Total commands executed', ['command', 'user'])
MESSAGE_COUNTER = Counter('discord_messages_total', 'Total messages received')
RESPONSE_TIME = Histogram('discord_command_duration_seconds', 'Command response time')
BOT_UPTIME = Gauge('discord_bot_uptime_seconds', 'Bot uptime in seconds')
SYSTEM_CPU = Gauge('discord_bot_system_cpu_percent', 'System CPU usage')
SYSTEM_MEMORY = Gauge('discord_bot_system_memory_percent', 'System memory usage')

class VICEBot(commands.Bot):
    def __init__(self, config_path='config.yml'):
        self.config = self.load_config(config_path)
        self.start_time = time.time()
        
        intents = discord.Intents.default()
        intents.message_content = True
        
        super().__init__(
            command_prefix=self.config['bot']['prefix'],
            intents=intents,
            help_command=None
        )
        
        # Start Prometheus metrics server
        start_http_server(self.config['monitoring']['metrics_port'])
        
        # Setup logging
        self.setup_logging()
        
    def load_config(self, config_path):
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r') as f:
                return yaml.safe_load(f)
        except FileNotFoundError:
            # Fallback to environment variables
            return {
                'bot': {
                    'token': os.getenv('BOT_TOKEN', 'YOUR_BOT_TOKEN_HERE'),
                    'prefix': os.getenv('BOT_PREFIX', '!'),
                    'status': 'online',
                    'activity': 'VICE Monitoring'
                },
                'monitoring': {
                    'enabled': True,
                    'metrics_port': int(os.getenv('METRICS_PORT', 8080)),
                    'health_check_interval': 30
                },
                'logging': {
                    'level': os.getenv('LOG_LEVEL', 'INFO')
                }
            }
    
    def setup_logging(self):
        """Setup logging configuration"""
        log_level = getattr(logging, self.config['logging']['level'].upper())
        logging.basicConfig(
            level=log_level,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler(self.config['logging']['file']),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    async def setup_hook(self):
        """Setup bot when starting"""
        await self.add_cog(MonitoringCog(self))
        await self.add_cog(SystemCog(self))
        self.logger.info("Bot setup completed")
    
    async def on_ready(self):
        """Called when bot is ready"""
        self.logger.info(f'Logged in as {self.user.name} ({self.user.id})')
        await self.change_presence(
            status=discord.Status[self.config['bot']['status']],
            activity=discord.Game(name=self.config['bot']['activity'])
        )
        
        # Start background tasks
        self.bg_task = self.loop.create_task(self.update_metrics())
    
    async def on_message(self, message):
        """Handle incoming messages"""
        if message.author.bot:
            return
            
        MESSAGE_COUNTER.inc()
        await self.process_commands(message)
    
    async def update_metrics(self):
        """Update system metrics periodically"""
        while True:
            try:
                # Update uptime
                BOT_UPTIME.set(time.time() - self.start_time)
                
                # Update system metrics
                SYSTEM_CPU.set(psutil.cpu_percent())
                SYSTEM_MEMORY.set(psutil.virtual_memory().percent)
                
                await asyncio.sleep(self.config['monitoring']['health_check_interval'])
            except Exception as e:
                self.logger.error(f"Error updating metrics: {e}")
                await asyncio.sleep(60)

class MonitoringCog(commands.Cog):
    def __init__(self, bot):
        self.bot = bot
    
    @commands.command(name='status')
    async def status(self, ctx):
        """Show bot status and system information"""
        start_time = time.time()
        
        embed = discord.Embed(
            title="🤖 VICE Bot Status",
            color=discord.Color.green()
        )
        
        # Bot info
        embed.add_field(
            name="Bot Status",
            value=f"✅ Online\nUptime: {time.time() - self.bot.start_time:.0f}s",
            inline=True
        )
        
        # System info
        cpu_percent = psutil.cpu_percent()
        memory = psutil.virtual_memory()
        
        embed.add_field(
            name="System Status",
            value=f"CPU: {cpu_percent}%\nMemory: {memory.percent}%",
            inline=True
        )
        
        # Guild info
        embed.add_field(
            name="Guild Info",
            value=f"Guilds: {len(self.bot.guilds)}\nUsers: {len(self.bot.users)}",
            inline=True
        )
        
        await ctx.send(embed=embed)
        
        # Record metrics
        COMMAND_COUNTER.labels(command='status', user=str(ctx.author.id)).inc()
        RESPONSE_TIME.observe(time.time() - start_time)
    
    @commands.command(name='ping')
    async def ping(self, ctx):
        """Show bot latency"""
        start_time = time.time()
        
        latency = round(self.bot.latency * 1000)
        color = discord.Color.green() if latency < 100 else discord.Color.yellow() if latency < 200 else discord.Color.red()
        
        embed = discord.Embed(
            title="🏓 Pong!",
            description=f"Latency: {latency}ms",
            color=color
        )
        
        await ctx.send(embed=embed)
        
        # Record metrics
        COMMAND_COUNTER.labels(command='ping', user=str(ctx.author.id)).inc()
        RESPONSE_TIME.observe(time.time() - start_time)

class SystemCog(commands.Cog):
    def __init__(self, bot):
        self.bot = bot
    
    @commands.command(name='system')
    @commands.has_permissions(administrator=True)
    async def system_info(self, ctx):
        """Show detailed system information (Admin only)"""
        start_time = time.time()
        
        embed = discord.Embed(
            title="🖥️ System Information",
            color=discord.Color.blue()
        )
        
        # CPU info
        cpu_count = psutil.cpu_count()
        cpu_percent = psutil.cpu_percent(interval=1)
        embed.add_field(
            name="CPU",
            value=f"Cores: {cpu_count}\nUsage: {cpu_percent}%",
            inline=True
        )
        
        # Memory info
        memory = psutil.virtual_memory()
        embed.add_field(
            name="Memory",
            value=f"Total: {memory.total // (1024**3)}GB\nUsed: {memory.percent}%",
            inline=True
        )
        
        # Disk info
        disk = psutil.disk_usage('/')
        embed.add_field(
            name="Disk",
            value=f"Total: {disk.total // (1024**3)}GB\nUsed: {disk.percent}%",
            inline=True
        )
        
        await ctx.send(embed=embed)
        
        # Record metrics
        COMMAND_COUNTER.labels(command='system', user=str(ctx.author.id)).inc()
        RESPONSE_TIME.observe(time.time() - start_time)

def main():
    """Main function"""
    bot = VICEBot()
    
    try:
        bot.run(bot.config['bot']['token'])
    except KeyboardInterrupt:
        bot.logger.info("Bot stopped by user")
    except Exception as e:
        bot.logger.error(f"Bot error: {e}")

if __name__ == "__main__":
    main() 