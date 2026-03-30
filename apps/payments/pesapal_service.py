import requests
import uuid
import logging
import os
from django.conf import settings
from django.core.cache import cache
from decouple import config

logger = logging.getLogger(__name__)
_pesapal_session = requests.Session()
_pesapal_session.headers.update({
    "Accept": "application/json",
    "Content-Type": "application/json"
})

class PesapalService:
    def __init__(self, config_obj=None):
        if config_obj:
            self.consumer_key = config_obj.credentials.get('consumer_key')
            self.consumer_secret = config_obj.credentials.get('consumer_secret')
            self.sandbox = config_obj.is_sandbox
            self.callback_url = config_obj.credentials.get('callback_url', settings.PESAPAL_CALLBACK_URL)
        else:
            self.consumer_key = settings.PESAPAL_CONSUMER_KEY
            self.consumer_secret = settings.PESAPAL_CONSUMER_SECRET
            self.sandbox = settings.PESAPAL_SANDBOX
            self.callback_url = settings.PESAPAL_CALLBACK_URL
        
        if self.sandbox:
            self.base_url = "https://cybqa.pesapal.com/pesapalv3"
        else:
            self.base_url = "https://pay.pesapal.com/v3"

    @staticmethod
    def get_config_for_country(country):
        """Helper to get Pesapal config for a country"""
        from .models import PaymentGatewayConfig, PaymentGateway
        
        if not country:
            return None
            
        filter_kwargs = {
            'gateway': PaymentGateway.PESAPAL,
            'is_active': True
        }
        
        if isinstance(country, str):
            filter_kwargs['country__name'] = country
        else:
            filter_kwargs['country'] = country
            
        return PaymentGatewayConfig.objects.filter(**filter_kwargs).first()

    def get_token(self, force_refresh=False):
        """Get authentication token from PesaPal V3 with caching"""
        env = "sandbox" if self.sandbox else "live"
        cache_key = f"pesapal_auth_token_{env}_{self.consumer_key[:8]}"
        
        if not force_refresh:
            try:
                token = cache.get(cache_key)
                if token:
                    return token
            except Exception as e:
                logger.error(f"Pesapal: Cache get error: {str(e)}")

        url = f"{self.base_url}/api/Auth/RequestToken"
        payload = {
            "consumer_key": self.consumer_key,
            "consumer_secret": self.consumer_secret
        }
        
        try:
            response = _pesapal_session.post(url, json=payload, timeout=30)
            response.raise_for_status()
            
            data = response.json()
            if data.get('error'):
                logger.error(f"Pesapal Auth Error: {data.get('error')}")
                return None
                
            token = data.get('token')
            if token:
                try:
                    cache.set(cache_key, token, timeout=3300)
                except Exception as e:
                    logger.error(f"Pesapal: Cache set error: {str(e)}")
            return token
        except Exception as e:
            logger.error(f"PesaPal get_token error: {str(e)}")
            return None

    def register_ipn(self, token):
        """Register IPN URL with PesaPal if not already done"""
        url = f"{self.base_url}/api/URLSetup/RegisterIPN"
        ipn_url = self.callback_url.replace('/callback/', '/ipn/')
        if ipn_url == self.callback_url:

             ipn_url = self.callback_url + 'ipn/'

        payload = {
            "url": ipn_url,
            "ipn_notification_type": "POST" 
        }
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
        
        try:
            logger.info(f"Pesapal: Registering IPN URL: {ipn_url}")
            response = _pesapal_session.post(url, json=payload, headers=headers, timeout=30)
            if response.status_code == 401:
                logger.error("Pesapal: IPN registration failed with 401 Unauthorized")
                return None
            response.raise_for_status()
            return response.json().get('ipn_id')
        except Exception as e:
            logger.error(f"PesaPal register_ipn error: {str(e)}")
            return None

    def create_payment(self, amount, merchant_reference, description, user, currency="UGX", retry_on_401=True, card_token=None):
        """Create a payment request and return redirect URL"""
        logger.info(f"Pesapal: Starting create_payment for user {user.id}, reference {merchant_reference}")
        if card_token:
            logger.info("Pesapal: Using saved card token for direct charging")
        
        token = self.get_token()
        if not token:
            logger.error("Pesapal: Failed to get auth token")
            return {'error': 'Failed to authenticate with Pesapal'}
            
        logger.info("Pesapal: Auth token obtained successfully")
        url = f"{self.base_url}/api/Transactions/SubmitOrderRequest"
        env = "sandbox" if self.sandbox else "live"
        cache_key = f"pesapal_ipn_id_{env}_{(self.consumer_key or '')[:8]}"
        
        ipn_id = None
        try:
            ipn_id = cache.get(cache_key)
        except Exception as e:
            logger.error(f"Pesapal: Cache get error: {str(e)}")
        
        if not ipn_id:
            logger.info("Pesapal: IPN ID not in cache, checking settings fallback...")
            ipn_id = getattr(settings, 'PESAPAL_IPN_ID', None)
            
        if not ipn_id:
            logger.info("Pesapal: IPN ID not in settings, registering new one...")
            ipn_id = self.register_ipn(token)
            if ipn_id:
                try:
                    cache.set(cache_key, ipn_id, timeout=86400 * 7) 
                    logger.info(f"Pesapal: Registered and cached IPN ID: {ipn_id}")
                except Exception as e:
                    logger.error(f"Pesapal: Cache set error: {str(e)}")
            else:
                logger.error("Pesapal: Failed to register IPN ID via API (check for 401/credentials)")
        else:
            logger.info(f"Pesapal: Using IPN ID: {ipn_id}")
                
        if not ipn_id:
            logger.error("Pesapal: Failed to register/get IPN ID")
            return {'error': 'Failed to register IPN URL. Please ensure PESAPAL_IPN_ID is set in environment or API registration is working.'}
        
        formatted_amount = round(float(amount), 2)
        phone = str(user.phone) if user.phone else "0000000000"
        if phone.startswith('+'):
            phone = phone[1:]
        phone = phone.replace(' ', '')

        payload = {
            "id": merchant_reference,
            "currency": currency,
            "amount": formatted_amount,
            "description": description,
            "callback_url": self.callback_url,
            "notification_id": ipn_id,
            "account_number": str(user.id),
            "billing_address": {
                "email_address": user.email or "user@jambopark.com",
                "phone_number": phone,
                "country_code": "UG",
                "first_name": (user.first_name or "Partner")[:30],
                "last_name": (user.last_name or "User")[:30]
            }
        }
        
        if card_token:
            payload["token"] = card_token

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }

        logger.info(f"Pesapal: Sending SubmitOrderRequest to {url}")
        try:
            response = _pesapal_session.post(url, json=payload, headers=headers, timeout=15)
            
            if response.status_code == 401 and retry_on_401:
                logger.warning("Pesapal: SubmitOrderRequest returned 401. Clearing cache and retrying...")
                auth_cache_key = f"pesapal_auth_token_{env}_{self.consumer_key[:8]}"
                cache.delete(auth_cache_key)
                cache.delete(cache_key)
                return self.create_payment(amount, merchant_reference, description, user, currency, retry_on_401=False, card_token=card_token)

            logger.info(f"Pesapal: Received response status {response.status_code}")
            response.raise_for_status()
            data = response.json()
            logger.info(f"Pesapal: Order submitted successfully. TrackingID: {data.get('order_tracking_id')}")
            return data
        except Exception as e:
            logger.error(f"Pesapal: SubmitOrderRequest error: {str(e)}")
            if hasattr(e, 'response') and e.response is not None:
                 logger.error(f"Pesapal: Error response body: {e.response.text}")
                 return {'error': f"Pesapal API Error: {e.response.text}"}
            return {'error': str(e)}

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
            response = _pesapal_session.get(url, headers=headers, timeout=30)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"PesaPal get_transaction_status error: {str(e)}")
            return None
