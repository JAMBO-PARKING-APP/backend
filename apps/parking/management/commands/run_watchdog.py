import logging
import time
from django.core.management.base import BaseCommand
from celery.utils.log import get_task_logger

logger = get_task_logger(__name__)

class Command(BaseCommand):
    help = 'Runs the system health watchdog directly (bypassing celery)'

    def add_arguments(self, parser):
        parser.add_argument(
            '--continuous',
            action='store_true',
            help='Run the watchdog continuously on an interval',
        )
        parser.add_argument(
            '--interval',
            type=int,
            default=60,
            help='Interval in seconds for continuous mode',
        )

    def handle(self, *args, **options):
        from apps.parking.tasks import cleanup_slot_statuses, check_expired_sessions
        self.stdout.write(self.style.SUCCESS('Starting Watchdog Management Command...'))

        def run_cycle():
            res1 = cleanup_slot_statuses()
            logger.info(res1)
            self.stdout.write(res1)
            res2 = check_expired_sessions()
            logger.info(res2)
            self.stdout.write(res2)

        if options['continuous']:
            interval = options['interval']
            self.stdout.write(f'Running continuously every {interval} seconds. Press Ctrl+C to stop.')
            try:
                while True:
                    run_cycle()
                    time.sleep(interval)
            except KeyboardInterrupt:
                self.stdout.write(self.style.SUCCESS('\nWatchdog stopped.'))
        else:
            run_cycle()
            self.stdout.write(self.style.SUCCESS('Watchdog tasks completed.'))
