import requests
import uuid
import logging
from django.conf import settings
from decouple import config

logger = logging.getLogger(__name__)

class PesapalService:
    def __init__(self):
        self.consumer_key = settings.PESAPAL_CONSUMER_KEY
        self.consumer_secret = settings.PESAPAL_CONSUMER_SECRET
        self.sandbox = settings.PESAPAL_SANDBOX
        
        if self.sandbox:
            self.base_url = "https://cybqa.pesapal.com/pesapalv3"
        else:
            self.base_url = "https://pay.pesapal.com/v3"

    def get_token(self):
        """Get authentication token from PesaPal"""
        url = f"{self.base_url}/api/Auth/RequestToken"
        payload = {
            "consumer_key": self.consumer_key,
            "consumer_secret": self.consumer_secret
        }
        
        try:
            print(f"DEBUG: PesaPal RequestToken URL: {url}")
            response = requests.post(url, json=payload)
            print(f"DEBUG: PesaPal RequestToken Status: {response.statusCode}")
            response.raise_for_status()
            token = response.json().get('token')
            print(f"DEBUG: PesaPal Token received: {token[:10]}...")
            return token
        except Exception as e:
            logger.error(f"PesaPal get_token error: {str(e)}")
            print(f"ERROR: PesaPal get_token error: {str(e)}")
            return None

    def register_ipn(self, token, callback_url):
        """Register IPN URL with PesaPal"""
        url = f"{self.base_url}/api/URLSetup/RegisterIPN"
        payload = {
            "url": callback_url,
            "ipn_notification_type": "GET"
        }
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        try:
            print(f"DEBUG: PesaPal RegisterIPN URL: {url}, Callback: {callback_url}")
            response = requests.post(url, json=payload, headers=headers)
            print(f"DEBUG: PesaPal RegisterIPN Status: {response.statusCode}")
            print(f"DEBUG: PesaPal RegisterIPN Response: {response.text}")
            response.raise_for_status()
            return response.json().get('ipn_id')
        except Exception as e:
            logger.error(f"PesaPal register_ipn error: {str(e)}")
            print(f"ERROR: PesaPal register_ipn error: {str(e)}")
            return None

    def submit_order(self, token, order_data):
        """Submit order to PesaPal and get redirect URL"""
        url = f"{self.base_url}/api/Transactions/SubmitOrderRequest"
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        try:
            print(f"DEBUG: PesaPal SubmitOrder URL: {url}")
            response = requests.post(url, json=order_data, headers=headers)
            print(f"DEBUG: PesaPal SubmitOrder Status: {response.statusCode}")
            print(f"DEBUG: PesaPal SubmitOrder Response: {response.text}")
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"PesaPal submit_order error: {str(e)}")
            print(f"ERROR: PesaPal submit_order error: {str(e)}")
            return None

    def get_transaction_status(self, token, order_tracking_id):
        """Get transaction status from PesaPal"""
        url = f"{self.base_url}/api/Transactions/GetTransactionStatus?orderTrackingId={order_tracking_id}"
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        try:
            response = requests.get(url, headers=headers)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"PesaPal get_transaction_status error: {str(e)}")
            return None
