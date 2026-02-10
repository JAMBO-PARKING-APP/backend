import requests
import uuid
import logging
import os
from django.conf import settings
from decouple import config

logger = logging.getLogger(__name__)

class PesapalService:
    def __init__(self):
        self.consumer_key = settings.PESAPAL_CONSUMER_KEY
        self.consumer_secret = settings.PESAPAL_CONSUMER_SECRET
        self.sandbox = settings.PESAPAL_SANDBOX
        self.callback_url = settings.PESAPAL_CALLBACK_URL
        
        if self.sandbox:
            self.base_url = "https://cybqa.pesapal.com/pesapalv3"
        else:
            self.base_url = "https://pay.pesapal.com/v3"

    def get_token(self):
        """Get authentication token from PesaPal V3"""
        url = f"{self.base_url}/api/Auth/RequestToken"
        payload = {
            "consumer_key": self.consumer_key,
            "consumer_secret": self.consumer_secret
        }
        
        try:
            response = requests.post(url, json=payload)
            response.raise_for_status()
            token = response.json().get('token')
            return token
        except Exception as e:
            logger.error(f"PesaPal get_token error: {str(e)}")
            return None

    def register_ipn(self, token):
        """Register IPN URL with PesaPal if not already done"""
        url = f"{self.base_url}/api/URLSetup/RegisterIPN"
        payload = {
            "url": self.callback_url,
            "ipn_notification_type": "GET"
        }
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        try:
            response = requests.post(url, json=payload, headers=headers)
            response.raise_for_status()
            return response.json().get('ipn_id')
        except Exception as e:
            logger.error(f"PesaPal register_ipn error: {str(e)}")
            return None

    def create_payment(self, amount, merchant_reference, description, user, currency="UGX"):
        """Create a payment request and return redirect URL"""
        token = self.get_token()
        if not token:
            return None
            
        url = f"{self.base_url}/api/Transactions/SubmitOrderRequest"
        
        # Registration of IPN might be needed for every transaction or once.
        # V3 usually expects an IPN ID.
        ipn_id = self.register_ipn(token)
        if not ipn_id:
            logger.error("Failed to register/get IPN ID")
            return None

        payload = {
            "id": merchant_reference,
            "currency": currency,
            "amount": float(amount),
            "description": description,
            "callback_url": self.callback_url,
            "notification_id": ipn_id,
            "billing_address": {
                "email_address": user.email or "user@jambopark.com",
                "phone_number": user.phone or "0000000000",
                "country_code": "UG",
                "first_name": user.first_name or "Guest",
                "last_name": user.last_name or "User"
            }
        }

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }

        try:
            response = requests.post(url, json=payload, headers=headers)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"PesaPal create_payment error: {str(e)}")
            return None

    def get_transaction_status(self, order_tracking_id):
        """Get transaction status from PesaPal"""
        token = self.get_token()
        if not token:
            return None
            
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
