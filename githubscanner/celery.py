from __future__ import absolute_import
import os

from celery import Celery

REDIS_URL = os.environ['OPENREDIS_URL']


class Config:
    BROKER_URL = REDIS_URL
    CELERY_RESULT_BACKEND = REDIS_URL
    CELERY_ENABLE_UTC = True
    CELERY_TIMEZONE = 'Asia/Jerusalem'

celery = Celery('githubscanner.celery',
                include=['githubscanner.tasks'])

celery.config_from_object(Config)

if __name__ == '__main__':
    celery.start()
