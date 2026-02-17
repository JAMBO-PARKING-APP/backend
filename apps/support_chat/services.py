import re
import math
import json
import random
from django.utils import timezone
from django.conf import settings
from django.urls import reverse
from apps.parking.models import Zone, ParkingSession, ParkingSlot
from apps.accounts.models import User
from apps.payments.models import WalletTransaction, Transaction
from apps.support_chat.models import AIChatContext
from apps.enforcement.models import Violation
from apps.rewards.models import LoyaltyAccount
from decimal import Decimal
from django.db.models import Q, Sum, Avg, Count
from datetime import timedelta, datetime
from typing import Dict, List, Optional, Tuple, Any
from enum import Enum
import logging

logger = logging.getLogger(__name__)

class IntentType(Enum):
    GREETING = "greeting"
    CHECK_BALANCE = "check_balance"
    CHECK_SESSION = "check_session"
    START_PARKING = "start_parking"
    STOP_PARKING = "stop_parking"
    TOP_UP = "top_up"
    TRANSACTION_HISTORY = "transaction_history"
    PARKING_INFO = "parking_info"
    PRICING_INFO = "pricing_info"
    VEHICLE_INFO = "vehicle_info"
    PAYMENT_HELP = "payment_help"
    ZONE_INFO = "zone_info"
    VIOLATION_INFO = "violation_info"
    LOYALTY_INFO = "loyalty_info"
    APP_HELP = "app_help"
    EMERGENCY_SUPPORT = "emergency_support"
    CANCEL = "cancel"
    CONFIRM = "confirm"
    FALLBACK = "fallback"
    COMPARISON = "comparison"
    RECOMMENDATION = "recommendation"
    PREDICTION = "prediction"

class EntityType(Enum):
    ZONE = "zone"
    AMOUNT = "amount"
    VEHICLE = "vehicle"
    TIME = "time"
    LOCATION = "location"
    DATE = "date"
    DURATION = "duration"
    VIOLATION_ID = "violation_id"
    TICKET_NUMBER = "ticket_number"

class ReasoningAIService:
    """
    Advanced Reasoning AI Engine with contextual understanding,
    intent classification, entity extraction, and dynamic response generation.
    """
    
    def __init__(self):
        self.zone_cache = self._build_zone_cache()
        self.user_contexts = {}  # In-memory context cache for performance
        self.intent_patterns = self._initialize_intent_patterns()
        self.entity_patterns = self._initialize_entity_patterns()
        self.response_templates = self._initialize_response_templates()
        self.knowledge_base = self._initialize_knowledge_base()
        
        # Professional specialized engines
        self.encyclopedia = AIPolicyEncyclopedia()
        self.sentiment_manager = UserSentimentManager()
        self.optimizer = ParkingOptimizationEngine(self.zone_cache)
        
    def _build_zone_cache(self) -> Dict:
        """Build comprehensive zone cache with metadata"""
        zones = Zone.objects.filter(is_active=True)
        cache = {}
        for zone in zones:
            cache[zone.name.lower()] = {
                'id': str(zone.id),
                'name': zone.name,
                'rate': float(zone.hourly_rate),
                'capacity': zone.total_slots,
                'available': zone.available_slots,
                'latitude': float(zone.latitude) if zone.latitude else None,
                'longitude': float(zone.longitude) if zone.longitude else None,
                'peak_hours': getattr(zone, 'peak_hours', {}),
                'amenities': getattr(zone, 'amenities', []),
                'popularity_score': self._calculate_zone_popularity(zone)
            }
        return cache

    def _calculate_zone_popularity(self, zone) -> float:
        """Calculate zone popularity based on historical data"""
        thirty_days_ago = timezone.now() - timedelta(days=30)
        sessions_count = ParkingSession.objects.filter(
            zone=zone, 
            created_at__gte=thirty_days_ago
        ).count()
        return min(sessions_count / 100, 1.0)  # Normalize to 0-1

    def _initialize_intent_patterns(self) -> Dict[IntentType, List[str]]:
        """Initialize comprehensive intent patterns with regex"""
        return {
            IntentType.GREETING: [
                r'\b(hi|hello|hey|greetings|good\s*(morning|afternoon|evening)|howdy|sup|yo)\b',
                r"\b(what'?s\s*up|nice\s*to\s*meet\s*you)\b"
            ],
            IntentType.CHECK_BALANCE: [
                r"\b(balance|wallet|how\s*much\s*(money|cash|funds)|check\s*(balance|wallet)|available\s*(balance|credit)|what'?s\s*my\s*balance)\b",
                r'\b(show\s*(balance|wallet)|wallet\s*balance|current\s*balance)\b'
            ],
            IntentType.CHECK_SESSION: [
                r'\b(active\s*session|current\s*parking|where\s*am\s*i\s*parked|my\s*parking\s*status|am\s*i\s*parked|parking\s*session|time\s*left|remaining\s*time|when\s*does\s*it\s*end)\b',
                r'\b(check\s*(session|parking)|session\s*status|parking\s*status|how\s*much\s*longer)\b'
            ],
            IntentType.START_PARKING: [
                r'\b(start|begin|initiate|commence)\s*(parking|session|parking\s*session)\b',
                r'\b(park\s*(here|now|my\s*car|vehicle)|i\s*want\s*to\s*park|need\s*to\s*park|find\s*parking)\b',
                r'\b(start\s*parking\s*at|park\s*at|in)\s*([a-zA-Z0-9\s]+)\b'
            ],
            IntentType.STOP_PARKING: [
                r'\b(stop|end|finish|complete|terminate|close)\s*(parking|session|parking\s*session)\b',
                r"\b(leave|exit|done\s*parking|unpark|i'?m\s*leaving|ready\s*to\s*leave)\b",
                r'\b(stop\s*parking\s*at|end\s*session)\b'
            ],
            IntentType.TOP_UP: [
                r'\b(top\s*up|add|deposit|recharge|load|cash\s*in|credit)\s*(money|funds|cash|wallet)?\b',
                r'\b(add\s*(\d+)\s*to\s*wallet|top\s*up\s*(\d+)|deposit\s*(\d+))\b'
            ],
            IntentType.TRANSACTION_HISTORY: [
                r'\b(history|transactions|past\s*payments|recent\s*activity|statement|ledger|records|charges|spending|expenses)\b',
                r'\b(show\s*(history|transactions)|view\s*transactions|payment\s*history|where\s*did\s*i\s*spend)\b'
            ],
            IntentType.PARKING_INFO: [
                r'\b(parking\s*(spots?|spaces?|zones?|areas?|locations?)|where\s*can\s*i\s*park|available\s*(parking|spots?)|nearest\s*parking|find\s*(parking|spot)|nearby\s*(parking|zones?))\b',
                r'\b(is\s*there\s*parking|parking\s*near\s*me|closest\s*(parking|zone)|parking\s*facilities|parking\s*options)\b',
                r'\b(street\s*parking|off\s*street\s*parking|indoor\s*parking|secure\s*parking)\b'
            ],
            IntentType.PRICING_INFO: [
                r'\b(price|cost|rate|how\s*much|charge|fee|tariff|pricing|expensive|cheap|affordable|billing)\b',
                r"\b(what'?s\s*the\s*(price|rate)|parking\s*(rates?|costs?)|hourly\s*rate|pricing\s*tiers|member\s*discounts)\b"
            ],
            IntentType.VEHICLE_INFO: [
                r'\b(vehicle|car|auto|truck|bike|motorcycle|plate|registration|my\s*cars?|registered\s*vehicles|added\s*vehicles)\b',
                r'\b(show\s*(vehicles|cars)|list\s*vehicles|what\s*vehicles|my\s*plate|manage\s*cars)\b',
                r'\b(add\s*car|remove\s*vehicle|change\s*car)\b'
            ],
            IntentType.PAYMENT_HELP: [
                r'\b(payment|pay|how\s*to\s*pay|mobile\s*money|mtn|airtel|pesapal|card|credit\s*card|debit\s*card|method|option|momo|prompt|otp)\b',
                r'\b(payment\s*(methods?|options?)|accepted\s*payments|ways?\s*to\s*pay|pay\s*by\s*phone|top\s*up\s*issue)\b'
            ],
            IntentType.ZONE_INFO: [
                r'\b(tell\s*me\s*about|info\s*on|details?\s*for|what\s*is)\s*([a-zA-Z0-9\s]+)\s*(zone|area)?\b',
                r'\b(zone|area|location)\s*([a-zA-Z0-9\s]+)\b'
            ],
            IntentType.VIOLATION_INFO: [
                r'\b(violation|fine|ticket|penalty|citation|clamped|towed|impound)\b',
                r'\b(why\s*did\s*i\s*get\s*(a\s*)?ticket|my\s*fines|check\s*violations|pay\s*(my\s*)?fine)\b'
            ],
            IntentType.LOYALTY_INFO: [
                r'\b(points|rewards|loyalty|badge|tier|level|status|rewards\s*progress|jambo\s*points)\b',
                r'\b(my\s*points|how\s*many\s*points|redeem\s*points|rewards\s*history)\b'
            ],
            IntentType.APP_HELP: [
                r'\b(help|how\s*to|guide|tutorial|support|troubleshoot|app\s*problem|not\s*working|bug|issue)\b',
                r'\b(how\s*do\s*i\s*(use|park|pay)|feature\s*guide|contact\s*support)\b'
            ],
            IntentType.EMERGENCY_SUPPORT: [
                r'\b(emergency|stuck|accident|breakdown|tow|police|help\s*now|urgent|panic)\b',
                r'\b(my\s*car\s*is\s*stuck|tow\s*truck|emergency\s*number|immediate\s*help)\b'
            ],
            IntentType.CANCEL: [
                r"\b(cancel|abort|stop|nevermind|forget|ignore|don'?t\s*worry|never\s*mind|scratch\s*that)\b"
            ],
            IntentType.CONFIRM: [
                r"\b(yes|yeah|yep|sure|ok|okay|confirm|proceed|go\s*ahead|do\s*it|that'?s\s*right|correct|affirmative)\b"
            ],
            IntentType.COMPARISON: [
                r'\b(compare|vs|versus|cheaper|better|difference\s*between|which\s*(is\s*)?(better|cheaper))\b',
                r'\b(compare\s*zones?|zone\s*comparison|parking\s*comparison)\b'
            ],
            IntentType.RECOMMENDATION: [
                r'\b(recommend|suggest|best|ideal|optimal|perfect|suitable|good\s*option)\b',
                r'\b(what\s*do\s*you\s*(recommend|suggest)|where\s*should\s*i\s*park|which\s*zone)\b'
            ],
            IntentType.PREDICTION: [
                r'\b(predict|forecast|busy|full|crowded|available|chances|likelihood|probability)\b',
                r'\b(will\s*i\s*find\s*parking|is\s*it\s*busy\s*now|how\s*busy)\b'
            ]
        }

    def _initialize_entity_patterns(self) -> Dict[EntityType, str]:
        """Initialize entity extraction patterns"""
        return {
            EntityType.AMOUNT: r'\b(\d{3,})(?:\s*)(ugx|shillings|ksh|usd)?\b',
            EntityType.ZONE: r'\b(?:at|in|zone|area|location)\s+([a-zA-Z\s]{3,50})\b',
            EntityType.VEHICLE: r'\b(?:plate|car|vehicle|reg|registration)\s+([A-Z0-9]{3,10})\b',
            EntityType.TIME: r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm|hours?|hrs?)\b',
            EntityType.DURATION: r'\b(\d+)\s*(hours?|hrs?|minutes?|mins?|seconds?|secs?)\b',
            EntityType.VIOLATION_ID: r'\b(?:violation|ticket|fine)\s*(?:id|#|number)?\s*([A-Z0-9\-]{5,})\b'
        }

    def _initialize_response_templates(self) -> Dict[str, List[str]]:
        """Initialize dynamic response templates"""
        return {
            'greeting': [
                "Hello {name}! I'm your Jambo AI assistant. How can I help you with parking today?",
                "Hi {name}! Great to see you. Need help with parking or your wallet?",
                "Welcome back, {name}! I'm here to help with anything parking-related."
            ],
            'balance': [
                "Your current wallet balance is **{balance:,.0f} UGX**. {suggestion}",
                "You have **{balance:,.0f} UGX** in your wallet. {suggestion}",
                "Let me check... Your balance is **{balance:,.0f} UGX**. {suggestion}"
            ],
            'low_balance': [
                "You might want to top up soon.",
                "Consider adding funds for uninterrupted parking.",
                "Would you like to top up now?"
            ],
            'active_session': [
                "You're currently parked at **{zone}** with vehicle **{plate}**.\n⏱️ Time left: **{time_left}**\n💰 Estimated cost so far: **{cost:,.0f} UGX**",
                "Active parking session found:\n📍 Zone: **{zone}**\n🚗 Vehicle: **{plate}**\n⏱️ Remaining: **{time_left}**\n💰 Current charge: **{cost:,.0f} UGX**"
            ],
            'no_session': [
                "You don't have any active parking sessions at the moment.",
                "No active parking found. Would you like to start parking?",
                "You're not currently parked anywhere. Need help finding a spot?"
            ],
            'parking_recommendation': [
                "Based on your location and current availability, I recommend:\n{recommendations}\n\n{context}",
                "Here are the best parking options for you:\n{recommendations}\n\n{context}"
            ],
            'zone_info': [
                "**{name}** details:\n📍 Rate: **{rate:,.0f} UGX/hour**\n🅿️ Available: **{available}/{capacity} spots**\n📊 Popularity: **{popularity}**\n⏰ Peak hours: {peak_hours}\n{amenities}",
                "Information for {name}:\n• Hourly rate: {rate:,.0f} UGX\n• Available spaces: {available}/{capacity}\n• Current status: {status}\n• Peak times: {peak_hours}"
            ],
            'price_comparison': [
                "Here's how the zones compare:\n{comparison}\n\n{recommendation}",
                "Price comparison:\n{comparison}\n\n{recommendation}"
            ],
            'violation_info': [
                "I found {count} active violation(s) for your vehicles. Total fine amount: **{total:,.0f} UGX**.\n{violations}\nWould you like to pay them now?",
                "You have {count} outstanding violation(s). The total amount due is **{total:,.0f} UGX**. Let's get these settled to avoid any further penalties."
            ],
            'loyalty_info': [
                "You are currently at the **{tier}** level with **{points} Jambo Points**! 🏆 You need **{next_tier_points}** more points to reach the {next_tier} tier.\n{benefits}",
                "Great progress! You have **{points} points**. Keep parking and paying on time to unlock more rewards in the {next_tier} tier."
            ],
            'emergency': [
                "🚨 **Emergency Support Detected**\nIf you are in immediate danger, please call **999** or **112**.\nFor vehicle breakdowns or towing at Jambo Park, call our 24/7 recovery line: **+256 800 123 456**.\nStay safe!",
                "I'm sorry to hear you're in a tough spot. For urgent assistance or towing in our zones, please contact our dispatch team immediately at **+256 800 123 456**."
            ],
            'app_help': [
                "I'm here to guide you! What would you like to learn about?\n• How to start parking\n• Topping up your wallet\n• Managing your vehicles\n• Understanding our reward tiers",
                "Need a hand? I can help you navigate Jambo Space. You can ask me things like 'How do I pay?' or 'Can I refund my session?'"
            ],
            'fallback': [
                "I'm not sure I understood that correctly. Could you please rephrase? You can ask me about available parking, your wallet balance, or your loyalty points.",
                "I'm still learning and didn't quite catch that. Try asking about 'nearby parking' or 'check my balance'!"
            ]
        }

    def _initialize_knowledge_base(self) -> Dict:
        """
        Extensive Knowledge Base containing all Jambo Park policies, 
        procedures, FAQs, and domain-specific information.
        """
        return {
            'peak_hours': {
                'morning_rush': (7, 10),
                'lunchtime': (12, 14),
                'evening_rush': (16, 20),
                'night_events': (21, 23)
            },
            'fine_structure': {
                'overdue_parking': 5000,
                'unauthorized_zone': 15000,
                'wrong_way_parking': 10000,
                'double_parking': 20000,
                'blocking_entrance': 50000,
                'expired_license': 100000,
                'illegal_parking': 30000
            },
            'loyalty_tiers': {
                'Bronze': {'threshold': 0, 'multiplier': 1.0, 'perks': ['Basic support', 'Standard rates']},
                'Silver': {'threshold': 1000, 'multiplier': 1.2, 'perks': ['10% discount on first hour', 'Email support']},
                'Gold': {'threshold': 5000, 'multiplier': 1.5, 'perks': ['20% discount on first hour', 'Priority chat support', 'Reserved zone access']},
                'Platinum': {'threshold': 10000, 'multiplier': 2.0, 'perks': ['Free 30 mins daily', 'VIP valet discount', 'Personal support agent']}
            },
            'operating_hours': "Jambo Park operates 24/7 across most zones. However, specific street level loading zones are restricted between 8 AM and 6 PM.",
            'refund_policy': {
                'early_exit': "100% of remaining time is refunded to your wallet.",
                'failed_transaction': "Refunds for failed top-ups via Pesapal are processed within 24 hours.",
                'violation_dispute': "If a fine is overturned after appeal, the amount is credited back to your wallet."
            },
            'towing_procedures': {
                'impound_location': "Main Impound Yard, Plot 45, Industrial Area, Kampala.",
                'release_fee': 150000,
                'daily_storage': 10000,
                'contact': "+256 800 123 456"
            },
            'common_questions': {
                'how_to_park': "To start parking, ensure you are in a Jambo zone. Open the app, select the zone on the map, and tap 'Start Parking'. You can also ask me: 'Start parking at Garden City'.",
                'payment_methods': "We accept Mobile Money (MTN MoMo, Airtel Money) via Pesapal, Credit/Debit Cards (Visa, Mastercard), and our internal Jambo Wallet.",
                'wallet_benefits': "Using the Jambo Wallet is faster, qualifies you for higher loyalty points, and allows for instant automatic refunds of unused time.",
                'overdue_parking': "If your session expires but you haven't moved your car, you will be billed the standard hourly rate plus a 5,000 UGX penalty if caught by an officer.",
                'clamping': "Vehicles with more than 3 unpaid violations are eligible for clamping. Please pay your fines via the 'Violations' tab to avoid this.",
                'missing_vehicle': "If your vehicle is not where you left it, it may have been towed for a violation. Contact our recovery line at +256 800 123 456.",
                'changing_vehicles': "You can manage vehicles in the 'My Vehicles' section. Ensure the active vehicle matches your current plate to avoid fines.",
                'security': "Our zones are monitored by CCTV and periodic officer patrols, but we advise users not to leave valuables visible in their vehicles.",
                'receipts': "All parking receipts are available in your Transaction History. You can export them as PDF for tax or reimbursement purposes.",
                'disabled_parking': "We provide dedicated accessible spots in all zones. Unauthorized use of these spots incurs a 50,000 UGX fine.",
                'electric_charging': "Zones with 'EV' icons have charging stations. Charging is billed separately from parking @ 1,500 UGX per kW.",
                'forgot_to_stop': "If you forget to stop your session, it will automatically end at the planned end time. No further charges will occur beyond that.",
                'reservation_policy': "You can reserve a spot up to 48 hours in advance. Reservations are held for 15 minutes after the start time.",
                'night_rates': "Between 10 PM and 6 AM, some zones offer 'Night Cap' rates with a flat fee of 2,000 UGX for the entire duration.",
                'referral_program': "Invite friends using your referral code. You both get 1,000 UGX when they complete their first 1-hour session.",
                'app_connectivity': "If you lose internet while parked, don't worry. Your session is managed on our servers. You can end it once you're back online.",
                'lost_qr_code': "Officers can verify your session using your license plate number even if you cannot show your QR code.",
                'corporation_accounts': "We offer business accounts for fleets. Contact corporate@jambopark.com for bulk pricing and centralized billing.",
                'lost_and_found': "Found items in a parking zone can be handed to the nearest Jambo Officer or reported via the 'Support' screen.",
                'parking_limit': "Most zones have a 24-hour maximum duration. For long-term parking, please use our 'Airport' or 'Station' zones.",
                'car_wash': "Some premium zones offer car wash services. You can book a wash while you park directly through the app services menu.",
                'valet_service': "Valet is available at City Mall and Plaza zones. Drop your keys at the Jambo Valet kiosk; your car is handled by certified drivers.",
                'disputing_fines': "You have 48 hours to dispute a fine. Tap the fine in 'Violations' and select 'Appeal'. Upload a photo of the situation as evidence.",
                'airtel_money': "To pay via Airtel Money, select Pesapal and then choose the Airtel Money option. You will receive a prompt to enter your PIN.",
                'mtn_momo': "MTN MoMo is supported via Pesapal. Ensure you have enough balance including transaction fees before starting.",
                'international_drivers': "Foreign cars are welcome. Register with your plate and select your country of origin in the vehicle settings.",
                'helmet_storage': "Motorcycle zones include secure helmet lockers in specific locations like the City Square zone.",
                'multiple_sessions': "You can only have one active parking session per vehicle, but you can manage multiple vehicles on one account.",
                'loyalty_tiers_explained': "Bronze (0-1k pts), Silver (1k-5k pts), Gold (5k-10k pts), Platinum (10k+ pts). Points are earned per 1,000 UGX spent.",
                'how_to_earn_points': "You earn points for every paid session, on-time payments, and referring new users to Jambo Park.",
                'redeeming_points': "Points can be converted to wallet credit 1:1 once you reach 5,000 points, or used for partner vouchers.",
                'emergency_towing': "If you break down, call +256 800 123 456. Jambo members with 'Silver' tier or higher get 10% off towing fees.",
                'police_assistance': "In case of theft or vandalism, contact the nearest officer. We cooperate fully with local law enforcement and provide CCTV footage.",
                'app_bugs': "Please report any app issues to dev-support@jambopark.com. Include your Phone Number and OS version.",
                'operating_cities': "We currently operate in Kampala, Entebbe, and Jinja. More cities are coming soon!",
                'holiday_parking': "On public holidays, street parking is free in some zones. check the app for 'Holiday' tags on specific zones.",
                'parking_enforcement': "Enforcement is carried out by uniformed Jambo Officers. You can verify an officer's identity by their ID badge QR code.",
                'scanning_qr': "Officers scan your dashboard QR code or plate. Ensure your dashboard is clear or your app is ready to show the pass.",
                'extension_policy': "You can extend an active session twice. After that, you must start a new session (if availability permits).",
                'minimum_charge': "The minimum charge for any session is for 15 minutes of parking.",
                'maximum_refund': "Refunds are limited to the actual amount paid. Bonus credits or vouchers are non-refundable."
            }
        }

    def get_response(self, user, query: str, latitude: float = None, longitude: float = None) -> str:
        """
        Main entry point with full reasoning pipeline
        """
        try:
            # Normalize input
            query = query.strip()
            
            # Check for empty query
            if not query:
                return "How can I help you with parking today?"

            # Step 1: Check and handle active context
            if user.is_authenticated:
                context = self._get_or_create_context(user)
                if context.get('step') == 'WAITING_CONFIRMATION':
                    return self._handle_confirmation(user, context, query)
                if context.get('step') == 'WAITING_INPUT':
                    return self._handle_missing_input(user, context, query)

            # Step 2: Multi-intent detection and splitting
            sub_queries = self._split_complex_query(query)
            
            if len(sub_queries) > 1:
                return self._handle_multi_intent(user, sub_queries, latitude, longitude)

            # Step 3: Single intent processing with full reasoning
            return self._process_single_intent(user, query, latitude, longitude)

        except Exception as e:
            error_msg = str(e)
            logger.error(f"AI Service error: {error_msg}")
            
            # Intelligent error response
            if "unsupported operand type" in error_msg:
                return "I ran into a technical calculation error. I'm still learning how to handle precise currency values, but I've logged this for my developers to fix!"
            
            return f"I encountered an unexpected issue: {error_msg[:100]}. Please try rephrasing your request or check back later."

    def _process_single_intent(self, user, query: str, lat: float, lon: float) -> str:
        """Process a single intent with full reasoning pipeline and trace accumulation"""
        trace = []
        trace.append("🧠 Initializing Jambo AI reasoning core...")
        
        # Step 1: Classify intent with confidence scoring
        trace.append(f"🔍 Analyzing user intent: '{query[:50]}...'")
        intent, confidence = self._classify_intent(query)
        trace.append(f"✅ Classified as **{intent.value}** (Confidence: {confidence:.2f})")
        
        # Step 2: Extract entities
        trace.append("🧬 Extracting entities (zones, times, vehicles)...")
        entities = self._extract_entities(query)
        if entities:
            trace.append(f"📍 Entities found: {', '.join([str(k.value) for k in entities.keys()])}")
        
        # Step 3: Analyze Sentiment
        sentiment = self._perform_sentiment_analysis(query)
        trace.append(f"🎭 Sentiment analysis: **{sentiment}**")
        
        # Step 4: Gather context
        trace.append("📚 Retrieving user context and history...")
        context = self._gather_context(user, intent, entities)
        context['sentiment'] = sentiment
        context['query'] = query
        
        # Step 5: Apply reasoning
        trace.append(f"⚙️ Applying logic for {intent.value}...")
        reasoning_result = self._apply_reasoning(user, intent, entities, context, lat, lon)
        
        # Merge sub-reasoning justifications into trace
        if 'justification' in reasoning_result:
            for j in reasoning_result['justification']:
                trace.append(f"🧠 {j}")
        elif 'nearby_zones' in reasoning_result and reasoning_result['nearby_zones']:
            best = reasoning_result['nearby_zones'][0]
            trace.append(f"🎯 Evaluated {len(reasoning_result['nearby_zones'])} zones. Best fit: **{best['zone'].name}**.")
            for log in best.get('scoring_logic', []):
                trace.append(f"   ↳ {log}")
        
        reasoning_result['sentiment'] = sentiment
        reasoning_result['trace'] = trace
        
        # Step 6: Generate response
        trace.append("✍️ Synthesizing professional response...")
        response = self._generate_response(intent, reasoning_result, user, query)
        
        # Step 6.5: Apply Sentiment Personality Adjustment
        adjustment = self.sentiment_manager.get_adjustment_phrase(sentiment)
        response = f"{adjustment}{response}"
        
        # Step 6.8: Append the Brain (Reasoning Trace)
        trace.append("🏁 Reasoning complete.")
        thinking_block = "\n\n---\n**🧠 Jambo AI Reasoning Trace:**\n" + "\n".join([f"> {step}" for step in trace])
        response = f"{response}{thinking_block}"
        
        # Step 7: Update context memory and log trace
        self._update_context(user, intent, entities, response, reasoning_result)
        self._log_reasoning_trace(user, {
            'query': query,
            'intent': intent.value,
            'confidence': confidence,
            'sentiment': sentiment,
            'entities': {str(k): v for k, v in entities.items()}
        })
        
        return response

    def _classify_intent(self, query: str) -> Tuple[IntentType, float]:
        """Classify intent with confidence scoring"""
        query_lower = query.lower()
        best_intent = IntentType.FALLBACK
        best_score = 0.0
        
        for intent, patterns in self.intent_patterns.items():
            for pattern in patterns:
                if re.search(pattern, query_lower, re.IGNORECASE):
                    # Calculate confidence based on pattern match quality
                    match_length = len(re.search(pattern, query_lower).group())
                    confidence = min(match_length / len(query), 1.0)
                    
                    if confidence > best_score:
                        best_score = confidence
                        best_intent = intent
                        
                    # Boost confidence for exact matches
                    if match_length > len(query) * 0.7:
                        best_score = max(best_score, 0.9)
                        
        return best_intent, best_score

    def _extract_entities(self, query: str) -> Dict[EntityType, Any]:
        """Extract entities from query"""
        entities = {}
        query_lower = query.lower()
        
        for entity_type, pattern in self.entity_patterns.items():
            matches = re.findall(pattern, query_lower, re.IGNORECASE)
            if matches:
                if entity_type == EntityType.AMOUNT:
                    # Extract amount and normalize
                    amount = matches[0][0] if isinstance(matches[0], tuple) else matches[0]
                    entities[entity_type] = int(re.sub(r'\D', '', str(amount)))
                elif entity_type == EntityType.ZONE:
                    # Find matching zone from cache
                    zone_match = matches[0] if isinstance(matches[0], str) else matches[0][-1]
                    entities[entity_type] = self._find_closest_zone(zone_match.strip())
                elif entity_type == EntityType.DURATION:
                    # Parse duration into minutes
                    match = matches[0]
                    value = int(match[0])
                    unit = match[1].lower()
                    
                    if 'hour' in unit or 'hr' in unit:
                        entities[entity_type] = value * 60
                    elif 'minute' in unit or 'min' in unit:
                        entities[entity_type] = value
                    else:
                        entities[entity_type] = value
                else:
                    entities[entity_type] = matches[0]
                    
        return entities

    def _gather_context(self, user, intent: IntentType, entities: Dict) -> Dict:
        """Gather relevant context for reasoning"""
        context = {
            'time': timezone.now(),
            'user_history': {},
            'zone_data': {},
            'previous_interactions': []
        }
        
        if user.is_authenticated:
            # Get user's recent history
            recent_sessions = ParkingSession.objects.filter(
                vehicle__user=user
            ).order_by('-created_at')[:5]
            
            context['user_history']['recent_sessions'] = [
                {
                    'zone': s.zone.name,
                    'date': s.created_at,
                    'duration': s.duration_minutes
                } for s in recent_sessions
            ]
            
            # Get user's preferred zones
            preferred_zones = set()
            for session in recent_sessions:
                preferred_zones.add(session.zone.name)
            context['user_history']['preferred_zones'] = list(preferred_zones)
            
            # Get balance status
            context['user_history']['balance'] = float(user.wallet_balance)
            
        return context

    def _apply_reasoning(self, user, intent: IntentType, entities: Dict, 
                         context: Dict, lat: float, lon: float) -> Dict:
        """Apply reasoning logic based on intent"""
        
        reasoning_result = {
            'intent': intent,
            'entities': entities,
            'data': {},
            'recommendations': [],
            'warnings': [],
            'suggestions': []
        }
        
        if intent == IntentType.CHECK_BALANCE:
            reasoning_result = self._reason_balance(user, context)
            
        elif intent == IntentType.CHECK_SESSION:
            reasoning_result = self._reason_session(user, context)
            
        elif intent == IntentType.START_PARKING:
            reasoning_result = self._reason_start_parking(user, entities, context, lat, lon)
            
        elif intent == IntentType.PARKING_INFO:
            reasoning_result = self._reason_parking_info(user, entities, context, lat, lon)
            
        elif intent == IntentType.PRICING_INFO:
            reasoning_result = self._reason_pricing(user, entities, context)
            
        elif intent == IntentType.COMPARISON:
            reasoning_result = self._reason_comparison(user, entities, context)
            
        elif intent == IntentType.RECOMMENDATION:
            # Use Optimization Engine for Pro recommendations
            optimized = self.optimizer.get_optimized_recommendation(lat, lon, {})
            reasoning_result = self._reason_recommendation(user, entities, context, lat, lon)
            reasoning_result['optimized_pick'] = optimized
            
        elif intent == IntentType.PREDICTION:
            reasoning_result = self._reason_prediction(user, entities, context)

        elif intent == IntentType.VIOLATION_INFO:
            reasoning_result = self._reason_violations(user, entities)

        elif intent == IntentType.LOYALTY_INFO:
            reasoning_result = self._reason_loyalty(user)

        elif intent == IntentType.EMERGENCY_SUPPORT:
            reasoning_result = {'is_emergency': True}
            
        return reasoning_result

    def _reason_balance(self, user, context: Dict) -> Dict:
        """Reason about wallet balance with descriptive brain logic"""
        result = {
            'balance': context['user_history']['balance'] if user.is_authenticated else 0,
            'suggestion': '',
            'can_park': False,
            'recommended_topup': None,
            'justification': []
        }
        
        if user.is_authenticated:
            # Check if balance is sufficient for typical parking
            avg_rate = Zone.objects.aggregate(Avg('hourly_rate'))['hourly_rate__avg'] or 1000
            avg_cost = float(avg_rate)
            typical_session_cost = avg_cost * 2.0  # Assume 2-hour session
            
            result['justification'].append(f"Currency audit: Current balance {result['balance']:,.0f} UGX.")
            result['justification'].append(f"Threshold check: Average zone rate is {avg_cost:,.0f} UGX/hr.")
            
            if result['balance'] < typical_session_cost:
                result['suggestion'] = "Your balance is low for a typical parking session."
                result['recommended_topup'] = int(typical_session_cost * 1.5)  # Recommend 50% more
                result['can_park'] = False
                result['justification'].append(f"Inference: Balance is below 2-hour safety threshold ({typical_session_cost:,.0f} UGX).")
            else:
                result['suggestion'] = "You have sufficient balance for parking."
                result['can_park'] = True
                result['justification'].append("Inference: Funds are sufficient for immediate parking.")
                
        return result

    def _reason_session(self, user, context: Dict) -> Dict:
        """Reason about active parking session with descriptive brain logic"""
        result = {
            'has_active': False,
            'session_data': None,
            'suggestion': '',
            'justification': []
        }
        
        if user.is_authenticated:
            active = ParkingSession.objects.filter(
                vehicle__user=user, 
                status='active'
            ).select_related('zone', 'vehicle').first()
            
            if active:
                result['justification'].append(f"Active session identified: {active.id}.")
                now = timezone.now()
                elapsed = now - active.created_at
                remaining = active.planned_end_time - now
                
                cost_so_far = float(active.zone.hourly_rate) * (elapsed.total_seconds() / 3600)
                
                result['has_active'] = True
                result['session_data'] = {
                    'zone': active.zone.name,
                    'plate': active.vehicle.license_plate,
                    'started': active.created_at,
                    'elapsed': self._format_duration(elapsed),
                    'remaining': self._format_duration(remaining),
                    'cost_so_far': cost_so_far,
                    'estimated_total': active.estimated_cost
                }
                
                # Generate suggestions based on time
                if remaining.total_seconds() < 900:  # Less than 15 minutes
                    result['suggestion'] = "Your session is ending soon. Would you like to extend?"
                    result['justification'].append("Temporal alert: Less than 15 minutes remaining.")
                else:
                    result['justification'].append(f"Temporal check: {self._format_duration(remaining)} remaining.")
            else:
                result['justification'].append("Scan complete: No active sessions found for this identity.")
                    
        return result

    def _reason_start_parking(self, user, entities: Dict, context: Dict, lat: float, lon: float) -> Dict:
        """Reason about starting a parking session"""
        result = {
            'zone': None,
            'vehicle': None,
            'can_start': False,
            'issues': [],
            'alternatives': [],
            'duration_minutes': entities.get(EntityType.DURATION, 60),  # Default to 1 hour
            'requires_confirmation': False
        }
        
        if not user.is_authenticated:
            result['issues'].append("Please log in to start parking")
            return result
            
        # Check for vehicle
        vehicle = user.vehicles.filter(is_active=True).first()
        if not vehicle:
            result['issues'].append("No active vehicle found")
        else:
            result['vehicle'] = vehicle
            
        # Check for existing session
        if ParkingSession.objects.filter(vehicle__user=user, status='active').exists():
            result['issues'].append("You already have an active session")
            
        # Determine zone
        zone = entities.get(EntityType.ZONE)
        if not zone and lat and lon:
            zone = self._find_nearest_zone(lat, lon)
            
        if zone:
            zone_obj = Zone.objects.filter(name__iexact=zone).first()
            if zone_obj:
                if zone_obj.available_slots > 0:
                    result['zone'] = zone_obj
                    result['can_start'] = True
                    result['requires_confirmation'] = True
                else:
                    result['issues'].append(f"{zone_obj.name} is full")
                    # Find alternatives
                    result['alternatives'] = self._find_alternative_zones(zone_obj, lat, lon)
            else:
                result['issues'].append(f"Zone '{zone}' not found")
        else:
            result['issues'].append("Please specify a parking zone")
            
        # Check balance
        hourly_rate = float(zone_obj.hourly_rate) if zone_obj else 1000.0
        if float(user.wallet_balance) < hourly_rate:
            result['issues'].append("Insufficient balance")
            
        return result

    def _reason_policy(self, query: str) -> Dict:
        """Dynamically reason about parking policies using the knowledge base and encyclopedia"""
        query_lower = query.lower()
        result = {'policy_found': False, 'answer': None, 'related_topic': None, 'justification': []}
        
        # Priority 1: Check Encyclopedia Section (Deep Reasoning)
        sections = ['FINES', 'LOYALTY', 'PAYMENTS', 'SAFETY', 'CORPORATE']
        for section in sections:
            if section.lower() in query_lower:
                result['policy_found'] = True
                result['answer'] = self.encyclopedia.get_policy_summary(section)
                result['related_topic'] = section
                result['justification'].append(f"Located detailed policy in **Encyclopedia Section: {section}**.")
                return result

        # Priority 2: Check Common Questions
        for key, answer in self.knowledge_base['common_questions'].items():
            if key.replace('_', ' ') in query_lower:
                result['policy_found'] = True
                result['answer'] = answer
                result['related_topic'] = key
                result['justification'].append(f"Matched inquiry with **FAQ record: {key}**.")
                return result
                
        # Heuristic for policy types
        if 'fine' in query_lower or 'pay' in query_lower:
            result['answer'] = f"Standard fine for overdue parking is {self.knowledge_base['fine_structure']['overdue_parking']} UGX. Fines can be paid via the app wallet."
            result['policy_found'] = True
            result['justification'].append("Inferred violation inquiry; retrieved standard fine structure.")
        elif 'hour' in query_lower or 'times' in query_lower:
            result['answer'] = self.knowledge_base['operating_hours']
            result['policy_found'] = True
            result['justification'].append("Detected temporal query; retrieved operating hours policy.")
            
        return result

    def _reason_parking_info(self, user, entities: Dict, context: Dict, lat: float, lon: float) -> Dict:
        """Reason about parking information and availability with safety scoring"""
        # Check for policy question first
        policy_result = self._reason_policy(context.get('query', ''))
        if policy_result['policy_found']:
            return {'type': 'policy', 'data': policy_result}

        result = {
            'type': 'availability',
            'nearby_zones': [],
            'recommendations': [],
            'summary': ''
        }
        
        if lat and lon:
            zones = Zone.objects.filter(is_active=True)
            zones_with_dist = []
            
            for zone in zones:
                if zone.latitude and zone.longitude:
                    dist = self._haversine(lat, lon, float(zone.latitude), float(zone.longitude))
                    if dist < 5:  # Within 5km
                        zone_meta = {
                            'amenities': getattr(zone, 'amenities', ['Lighting', 'Security'])
                        }
                        risk_data = self._calculate_zone_risk_score(zone_meta)
                        
                        score, scoring_logic = self._calculate_zone_score(zone, dist)
                        
                        zones_with_dist.append({
                            'zone': zone,
                            'distance': dist,
                            'available': zone.available_slots,
                            'rate': float(zone.hourly_rate),
                            'score': score,
                            'scoring_logic': scoring_logic,
                            'security': risk_data
                        })
            
            # Sort by score
            zones_with_dist.sort(key=lambda x: x['score'], reverse=True)
            result['nearby_zones'] = zones_with_dist[:5]
            
            # Generate summary based on brain reasoning
            if zones_with_dist:
                best = zones_with_dist[0]
                result['summary'] = f"Success! I've located {len(zones_with_dist)} zones near you. **{best['zone'].name}** is my top recommendation based on a performance score of {best['score']:.1f}."
            else:
                result['summary'] = "I analyzed the map but couldn't find any Jambo zones within a 5km radius."
                
        return result

    def _reason_pricing(self, user, entities: Dict, context: Dict) -> Dict:
        """Reason about pricing information"""
        result = {
            'zones': [],
            'average_rate': 0,
            'min_rate': 0,
            'max_rate': 0,
            'comparison': []
        }
        
        zones = Zone.objects.filter(is_active=True)
        if zones.exists():
            rates = [float(z.hourly_rate) for z in zones]
            avg_rate = sum(rates) / len(rates)
            result['average_rate'] = avg_rate
            result['min_rate'] = min(rates)
            result['max_rate'] = max(rates)
            
            # Group by price range
            result['zones'] = [
                {
                    'name': z.name,
                    'rate': float(z.hourly_rate),
                    'relative_price': 'premium' if float(z.hourly_rate) > avg_rate * 1.2 else 
                                     'budget' if float(z.hourly_rate) < avg_rate * 0.8 else 'standard'
                }
                for z in zones
            ]
            
        return result

    def _reason_comparison(self, user, entities: Dict, context: Dict) -> Dict:
        """Compare different zones or options"""
        result = {
            'comparisons': [],
            'best_value': None,
            'best_location': None
        }
        
        zones = Zone.objects.filter(is_active=True)[:3]  # Compare up to 3 zones
        
        if len(zones) >= 2:
            for zone in zones:
                # Calculate value score (price vs popularity)
                popularity = self._calculate_zone_popularity(zone)
                rate_float = float(zone.hourly_rate)
                value_score = popularity / (rate_float / 1000.0) if rate_float > 0 else 0
                
                result['comparisons'].append({
                    'zone': zone.name,
                    'rate': rate_float,
                    'available': zone.available_slots,
                    'popularity': popularity,
                    'value_score': value_score
                })
            
            # Find best value
            result['best_value'] = max(result['comparisons'], key=lambda x: x['value_score'])['zone']
            
        return result

    def _reason_recommendation(self, user, entities: Dict, context: Dict, lat: float, lon: float) -> Dict:
        """Generate personalized recommendations"""
        result = {
            'recommendations': [],
            'reasoning': ''
        }
        
        if lat and lon:
            zones = Zone.objects.filter(is_active=True)
            recommendations = []
            
            for zone in zones:
                if zone.latitude and zone.longitude:
                    dist = self._haversine(lat, lon, float(zone.latitude), float(zone.longitude))
                    
                    # Calculate recommendation score
                    score = 0
                    score += (5 - min(dist, 5)) * 2  # Distance factor (0-10)
                    score += min(zone.available_slots, 10) * 0.5  # Availability factor (0-5)
                    score += (1 - (float(zone.hourly_rate) / 5000)) * 5  # Price factor (0-5)
                    
                    # Personalization based on user history
                    if user.is_authenticated and context['user_history'].get('preferred_zones'):
                        if zone.name in context['user_history']['preferred_zones']:
                            score += 3  # Boost for previously used zones
                    
                    recommendations.append({
                        'zone': zone,
                        'score': score,
                        'distance': dist,
                        'reason': self._generate_recommendation_reason(zone, dist, score)
                    })
            
            # Sort by score
            recommendations.sort(key=lambda x: x['score'], reverse=True)
            result['recommendations'] = recommendations[:3]
            
        return result

    def _reason_prediction(self, user, entities: Dict, context: Dict) -> Dict:
        """Predict parking availability"""
        result = {
            'zone': None,
            'current_status': '',
            'trend': '',
            'prediction': '',
            'best_time': ''
        }
        
        zone_name = entities.get(EntityType.ZONE)
        if zone_name:
            zone = Zone.objects.filter(name__iexact=zone_name).first()
            if zone:
                now = timezone.now()
                hour = now.hour
                
                # Simple prediction based on time
                if 8 <= hour <= 10 or 17 <= hour <= 19:
                    trend = "busy (peak hours)"
                    prediction = "Expect high occupancy during these times."
                    best_time = "mid-day (11am-2pm)"
                elif 12 <= hour <= 14:
                    trend = "moderately busy (lunch hour)"
                    prediction = "Some spots available, but fills up quickly."
                    best_time = "after 2pm"
                else:
                    trend = "generally available"
                    prediction = "Good availability expected."
                    best_time = "now"
                    
                result['zone'] = zone.name
                result['current_status'] = f"{zone.available_slots}/{zone.total_slots} spots available"
                result['trend'] = trend
                result['prediction'] = prediction
                result['best_time'] = best_time
                
        return result

    def _generate_response(self, intent: IntentType, reasoning_result: Dict, user, query: str = "") -> str:
        """Generate natural language response from reasoning result"""
        
        if intent == IntentType.CHECK_BALANCE:
            if user.is_authenticated:
                balance = reasoning_result['balance']
                suggestion = reasoning_result['suggestion']
                
                if reasoning_result.get('recommended_topup'):
                    return f"Your current wallet balance is **{balance:,.0f} UGX**. {suggestion} Recommended top-up: **{reasoning_result['recommended_topup']:,} UGX**."
                else:
                    return f"Your current wallet balance is **{balance:,.0f} UGX**. {suggestion}"
            return "Please log in to check your wallet balance."
            
        elif intent == IntentType.CHECK_SESSION:
            if reasoning_result['has_active']:
                data = reasoning_result['session_data']
                response = f"You're currently parked at **{data['zone']}** with vehicle **{data['plate']}**.\n"
                response += f"⏱️ Time elapsed: {data['elapsed']}\n"
                response += f"⏱️ Time remaining: {data['remaining']}\n"
                response += f"💰 Current cost: **{data['cost_so_far']:,.0f} UGX**"
                
                if reasoning_result['suggestion']:
                    response += f"\n\n💡 {reasoning_result['suggestion']}"
                return response
            return "You don't have any active parking sessions at the moment."

        elif intent == IntentType.VIOLATION_INFO:
            if not user.is_authenticated:
                return "Please log in to check for any parking violations."
            
            data = reasoning_result
            if data['count'] > 0:
                violations_text = "\n".join([f"• {v['type']} at {v['zone']} - **{v['amount']:,.0f} UGX**" for v in data['violations']])
                return random.choice(self.response_templates['violation_info']).format(
                    count=data['count'],
                    total=data['total'],
                    violations=violations_text
                )
            return "Good news! You have no outstanding parking violations. Drive safely!"

        elif intent == IntentType.PARKING_INFO:
            data = reasoning_result
            if data.get('type') == 'policy':
                return data['data']['answer']
            
            if not data['nearby_zones']:
                return "I couldn't find any Jambo parking zones near your current location. Try zooming out on the map!"
                
            response = f"**{data['summary']}**\n\n"
            for idx, item in enumerate(data['nearby_zones'], 1):
                zone = item['zone']
                security = item['security']
                response += f"{idx}. **{zone.name}** ({item['distance']:.1f}km)\n"
                response += f"   💰 {item['rate']:,.0f} UGX/hr | 🅿️ {item['available']} spots\n"
                response += f"   🛡️ Security: **{security['level']}** ({', '.join(security['reasons'][:2])})\n"
                
            return response

        elif intent == IntentType.LOYALTY_INFO:
            if not user.is_authenticated:
                return "Please log in to see your Jambo Points and reward tier."
            
            data = reasoning_result
            response = random.choice(self.response_templates['loyalty_info']).format(
                tier=data['tier'],
                points=data['points'],
                next_tier_points=data['next_tier_points'],
                next_tier=data['next_tier'],
                benefits=data['benefits']
            )
            
            # Add specific guidance for points
            if data['points'] > 5000:
                response += "\n\n💡 You have enough points to redeem for 5,000 UGX wallet credit!"
            elif data['next_tier_points'] < 200:
                response += f"\n\n🚀 You're almost at the {data['next_tier']} tier! Just a few more sessions to go."
                
            return response

        elif intent == IntentType.EMERGENCY_SUPPORT:
            return random.choice(self.response_templates['emergency'])

        elif intent == IntentType.APP_HELP:
            # Check for keyword in query to give specific help
            query_lower = query.lower()
            if 'towing' in query_lower or 'impound' in query_lower:
                proc = self.knowledge_base['towing_procedures']
                return f"**Towing & Impound Protocol**\nYour vehicle may be towed for multiple violations or blocking access. \n📍 Impound Yard: {proc['impound_location']}\n💵 Release Fee: {proc['release_fee']:,.0f} UGX\n📞 Recovery Line: {proc['contact']}\nPlease have your plate number ready."
            
            if 'refund' in query_lower:
                return f"**Refund Policy**\n{self.knowledge_base['refund_policy']['early_exit']}\nIf you experience issues, refunds are typically processed within 24 hours back to your wallet."
            
            return random.choice(self.response_templates['app_help'])
            
        elif intent == IntentType.START_PARKING:
            if reasoning_result.get('can_start'):
                zone = reasoning_result['zone']
                vehicle = reasoning_result['vehicle']
                duration = reasoning_result.get('duration_minutes', 60)
                hourly_rate = float(zone.hourly_rate)
                total_est = hourly_rate * (duration / 60.0)
                
                return (
                    f"I'm ready to initiate a parking session for your vehicle **{vehicle.license_plate}** at **{zone.name}**.\n"
                    f"⏱️ Duration: **{self._format_duration(timedelta(minutes=duration))}**\n"
                    f"💰 Estimated Cost: **{total_est:,.0f} UGX** (@ {hourly_rate:,.0f}/hr)\n\n"
                    f"Please reply with 'Confirm' to authorize this session."
                )
            else:
                issues = "\n".join([f"• {i}" for i in reasoning_result['issues']])
                response = f"I can't start parking for you right now:\n{issues}"
                if reasoning_result.get('alternatives'):
                    alt_text = "\n".join([f"• {a['zone'].name} ({a['distance']:.1f}km)" for a in reasoning_result['alternatives']])
                    response += f"\n\nTry these nearby zones instead:\n{alt_text}"
                return response

        elif intent == IntentType.STOP_PARKING:
            if user.is_authenticated:
                active = ParkingSession.objects.filter(vehicle__user=user, status='active').first()
                if active:
                    return f"Ending parking for **{active.vehicle.license_plate}** at **{active.zone.name}**.\nReply 'Confirm' to end session and calculate final cost."
                return "You don't have an active session to end."
            return "Please log in to manage your parking sessions."

        elif intent == IntentType.PRICING_INFO:
            data = reasoning_result
            if not data.get('zones'):
                return "I couldn't find any pricing data at the moment. Generally, our rates start from 1,000 UGX/hour."
            
            avg = data['average_rate']
            response = f"The average parking rate across Jambo Park is **{avg:,.0f} UGX/hour**. Rates range from {data['min_rate']:,.0f} to {data['max_rate']:,.0f} UGX.\n\n"
            response += "Price categories:\n"
            for zone in data['zones']:
                emoji = "💰💰💰" if zone['relative_price'] == 'premium' else "💰💰" if zone['relative_price'] == 'standard' else "💰"
                response += f"{emoji} {zone['name']}: {zone['rate']:,.0f} UGX/hr\n"
            return response

        elif intent == IntentType.ZONE_INFO:
            zone_entities = reasoning_result.get('entities', {})
            zone_name = zone_entities.get(EntityType.ZONE)
            
            if not zone_name:
                return "Which zone would you like to know more about? You can say 'Tell me about City Square'."
            
            zone_data = self.zone_cache.get(zone_name.lower())
            if not zone_data:
                return f"I couldn't find a zone named '{zone_name}'. Try checking the map for active locations!"
            
            status = "Ready to park" if zone_data['available'] > 0 else "Currently full"
            peak = "7 AM - 10 AM, 5 PM - 8 PM" # Simulated
            
            return random.choice(self.response_templates['zone_info']).format(
                name=zone_data['name'],
                rate=zone_data['rate'],
                available=zone_data['available'],
                capacity=zone_data['capacity'],
                status=status,
                popularity=f"{int(zone_data['popularity_score'] * 100)}%",
                peak_hours=peak,
                amenities="Security, Lighting, Near ATM"
            )
            
        elif intent == IntentType.COMPARISON:
            data = reasoning_result
            if data['comparisons']:
                response = "Zone Comparison:\n"
                for comp in data['comparisons']:
                    response += f"\n**{comp['zone']}**\n"
                    response += f"  Rate: {comp['rate']:,.0f} UGX/hr\n"
                    response += f"  Available: {comp['available']} spots\n"
                    response += f"  Popularity: {comp['popularity']*100:.0f}%\n"
                
                if data['best_value']:
                    response += f"\n✨ Best value: **{data['best_value']}**"
                return response
            return "Not enough zones to compare."
            
        elif intent == IntentType.RECOMMENDATION:
            if reasoning_result['recommendations']:
                response = "As your professional assistant, I've analyzed the nearby zones and recommend:\n\n"
                
                # Check for optimized pick
                if 'optimized_pick' in reasoning_result:
                    opt = reasoning_result['optimized_pick']['zone']
                    score = reasoning_result['optimized_pick']['score']
                    response += f"⭐ **Top Selection: {opt['name']}** (Confidence Score: {score:.1f})\n"
                    response += f"   Reason: This zone offers the best balance of proximity, price, and availability right now.\n\n"

                for idx, rec in enumerate(reasoning_result['recommendations'], 1):
                    zone = rec['zone']
                    response += f"{idx}. **{zone.name}** ({rec['distance']:.1f}km)\n"
                    response += f"   {rec['reason']}\n"
                return response
            return "I couldn't find any suitable parking recommendations."
            
        elif intent == IntentType.PREDICTION:
            data = reasoning_result
            if data['zone']:
                return f"**{data['zone']}**\nCurrent: {data['current_status']}\nTrend: {data['trend']}\n{prediction}\nBest time to park: {best_time}"
            return "Please specify a zone for availability prediction."
            
        elif intent == IntentType.GREETING:
            name = user.first_name if user.is_authenticated else "friend"
            return random.choice(self.response_templates['greeting']).format(name=name)
            
        elif intent == IntentType.VEHICLE_INFO:
            if user.is_authenticated:
                vehicles = user.vehicles.all()
                if vehicles:
                    response = "Your registered vehicles:\n"
                    for v in vehicles:
                        response += f"• **{v.license_plate}** - {v.make} {v.model} ({'Active' if v.is_active else 'Inactive'})\n"
                    return response
                return "You haven't registered any vehicles yet. Add one in the 'My Vehicles' section."
            return "Please log in to view your vehicles."
            
        elif intent == IntentType.PAYMENT_HELP:
            return "**Payment Options:**\n\n" + \
                   "1. **Wallet** (Recommended)\n" + \
                   "   - Fastest way to pay\n" + \
                   "   - Auto-refund for unused time\n" + \
                   "   - Top up via Mobile Money or Card\n\n" + \
                   "2. **Mobile Money**\n" + \
                   "   - MTN Uganda\n" + \
                   "   - Airtel Uganda\n\n" + \
                   "3. **Card Payment**\n" + \
                   "   - Visa/Mastercard\n" + \
                   "   - Secure via PesaPal\n\n" + \
                   "Need help with anything specific?"
            
        else:
            return self._generate_fallback_response(query)

    def _handle_multi_intent(self, user, sub_queries: List[str], lat: float, lon: float) -> str:
        """Handle multiple intents in one query"""
        responses = []
        
        for query in sub_queries:
            if query.strip():
                response = self._process_single_intent(user, query.strip(), lat, lon)
                responses.append(response)
                
        if len(responses) > 1:
            return "\n\n---\n\n".join(responses)
        return responses[0] if responses else self._generate_fallback_response("")

    def _split_complex_query(self, query: str) -> List[str]:
        """Split complex queries into atomic intents"""
        # Check for conjunctions
        conjunctions = [r'\s+(?:and|also|plus|then|&)\s+', r',\s*']
        
        for conj in conjunctions:
            parts = re.split(conj, query)
            if len(parts) > 1:
                return parts
                
        return [query]

    def _handle_confirmation(self, user, context: Dict, query: str) -> str:
        """Handle confirmation flow"""
        query_lower = query.lower()
        
        if any(w in query_lower for w in ['yes', 'confirm', 'ok', 'sure', 'do it']):
            return self._execute_confirmed_action(user, context)
        elif any(w in query_lower for w in ['no', 'cancel', 'stop', 'don\'t']):
            self._clear_context(user)
            return "Action cancelled. How else can I help you?"
        else:
            return "Please reply with 'Yes' to confirm or 'No' to cancel."

    def _handle_missing_input(self, user, context: Dict, query: str) -> str:
        """Handle missing input collection"""
        # Check for cancellation
        if any(w in query.lower() for w in ['cancel', 'stop', 'nevermind']):
            self._clear_context(user)
            return "Action cancelled. What would you like to do instead?"
            
        # Process based on missing field
        missing_field = context.get('action_data', {}).get('missing_field')
        
        if missing_field == 'zone':
            # Try to find zone from input
            zone = self._find_closest_zone(query)
            if zone:
                # Found zone, proceed with action
                new_query = f"Start parking at {zone}"
                self._clear_context(user)
                return self._process_single_intent(user, new_query, None, None)
            else:
                return f"Sorry, I couldn't find a zone matching '{query}'. Please try again with a valid zone name."
                
        return "I'm not sure what information you're providing. Let's start over."

    def _execute_confirmed_action(self, user, context: Dict) -> str:
        """Execute confirmed action"""
        action_type = context.get('action_type')
        action_data = context.get('action_data', {})
        
        try:
            if action_type == 'START_PARKING':
                return self._execute_start_parking(user, action_data)
            elif action_type == 'STOP_PARKING':
                return self._execute_stop_parking(user, action_data)
            elif action_type == 'TOPUP_WALLET':
                return self._execute_topup(user, action_data)
        except Exception as e:
            logger.error(f"Action execution error: {str(e)}")
            return f"Sorry, I couldn't complete that action: {str(e)}"
        finally:
            self._clear_context(user)
            
        return "Action completed successfully!"

    def _execute_start_parking(self, user, data: Dict) -> str:
        """Execute start parking action"""
        if not data.get('vehicle_id') or not data.get('zone_id'):
            return "Missing vehicle or zone information. Please start over."

        try:
            vehicle = user.vehicles.get(id=data['vehicle_id'])
            zone = Zone.objects.get(id=data['zone_id'])
            
            # Check for existing session
            if ParkingSession.objects.filter(vehicle=vehicle, status='active').exists():
                return "You already have an active parking session!"
                
            # Calculate costs based on duration
            duration_mins = data.get('duration_minutes', 60)
            planned_end = timezone.now() + timedelta(minutes=duration_mins)
            
            # hourly_rate * (duration / 60)
            hourly_rate = float(zone.hourly_rate)
            estimated_cost = hourly_rate * (duration_mins / 60.0)
            
            # Check balance
            if user.wallet_balance < estimated_cost:
                return f"Insufficient balance ({user.wallet_balance:,.0f} UGX). You need {estimated_cost:,.0f} UGX."
                
            # Process payment
            user.wallet_balance -= estimated_cost
            user.save()
            
            WalletTransaction.objects.create(
                user=user,
                amount=estimated_cost,
                transaction_type='payment',
                status='completed',
                description=f'Parking at {zone.name}'
            )
            
            # Create session
            session = ParkingSession.objects.create(
                vehicle=vehicle,
                zone=zone,
                planned_end_time=planned_end,
                estimated_cost=estimated_cost,
                status='active'
            )
            
            return f"✅ Parking started successfully!\n\n" + \
                   f"📍 **Zone**: {zone.name}\n" + \
                   f"🚗 **Vehicle**: {vehicle.license_plate}\n" + \
                   f"⏱️ **Ends at**: {planned_end.strftime('%H:%M')}\n" + \
                   f"💰 **Charged**: {estimated_cost:,.0f} UGX\n\n" + \
                   f"Your session ID: {session.id}"
                   
        except Exception as e:
            raise Exception(f"Failed to start parking: {str(e)}")

    def _execute_stop_parking(self, user, data: Dict) -> str:
        """Execute stop parking action"""
        try:
            session = ParkingSession.objects.get(
                id=data['session_id'],
                status='active'
            )
            
            # End session
            session.end_session()
            
            # Calculate refund if applicable
            refund = 0
            if session.estimated_cost and session.final_cost:
                refund = max(0, session.estimated_cost - session.final_cost)
                
            response = f"✅ Session ended successfully!\n\n" + \
                      f"📍 **Zone**: {session.zone.name}\n" + \
                      f"🚗 **Vehicle**: {session.vehicle.license_plate}\n" + \
                      f"💰 **Final cost**: {session.final_cost:,.0f} UGX"
                      
            if refund > 0:
                response += f"\n💸 **Refunded**: {refund:,.0f} UGX"
                
            return response
            
        except Exception as e:
            raise Exception(f"Failed to stop parking: {str(e)}")

    def _execute_topup(self, user, data: Dict) -> str:
        """Execute top-up action"""
        amount = data.get('amount', 0)
        
        if amount <= 0:
            return "Invalid amount specified."
            
        return f"🔹 **Top-up initiated**\n\n" + \
               f"Amount: **{amount:,.0f} UGX**\n\n" + \
               f"Please complete payment using one of these methods:\n" + \
               f"1. **Mobile Money**: Dial *185# and follow prompts\n" + \
               f"2. **Online**: {settings.SITE_URL}/wallet/topup?amount={amount}\n\n" + \
               f"Your balance will update automatically after payment."

    def _get_or_create_context(self, user) -> Dict:
        """Get or create user context from database"""
        if user.id in self.user_contexts:
            return self.user_contexts[user.id]
            
        try:
            db_context, _ = AIChatContext.objects.get_or_create(user=user)
            context = {
                'step': db_context.step,
                'action_type': db_context.action_type,
                'action_data': db_context.action_data or {}
            }
            self.user_contexts[user.id] = context
            return context
        except:
            return {'step': 'IDLE', 'action_type': None, 'action_data': {}}

    def _update_context(self, user, intent: IntentType, entities: Dict, response: str, reasoning_result: Dict = None):
        """Update user context in memory and database"""
        if not user.is_authenticated:
            return
            
        context = {
            'last_intent': intent.value,
            'last_entities': {k.value: v for k, v in entities.items()},
            'last_response': response,
            'timestamp': timezone.now().isoformat()
        }
        
        # Update context state based on intent
        if intent == IntentType.START_PARKING and reasoning_result and reasoning_result.get('requires_confirmation'):
            zone_id = None
            vehicle_id = None
            
            if reasoning_result.get('zone') and hasattr(reasoning_result['zone'], 'id'):
                 zone_id = str(reasoning_result['zone'].id)
            
            if reasoning_result.get('vehicle') and hasattr(reasoning_result['vehicle'], 'id'):
                 vehicle_id = str(reasoning_result['vehicle'].id)

            context.update({
                'step': 'WAITING_CONFIRMATION',
                'action_type': 'START_PARKING',
                'action_data': {
                    'zone_id': zone_id,
                    'vehicle_id': vehicle_id,
                    'duration_minutes': reasoning_result.get('duration_minutes', 60)
                }
            })
            
            logger.info(f"Context updated: WAITING_CONFIRMATION for user {user.id}")
            
        elif "I need more information" in response or "Which zone" in response:
             context.update({
                'step': 'WAITING_INPUT',
                'action_data': {'missing_field': 'zone'}
            })
             logger.info(f"Context updated: WAITING_INPUT for user {user.id}")

        # Update in-memory cache
        if user.id not in self.user_contexts:
            self.user_contexts[user.id] = {}
        self.user_contexts[user.id].update(context)
        
        # Update database
        try:
            db_context, _ = AIChatContext.objects.get_or_create(user=user)
            db_context.last_context = context
            if 'step' in context:
                db_context.step = context['step']
                db_context.action_type = context.get('action_type')
                db_context.action_data = context.get('action_data')
            db_context.save()
        except Exception as e:
            logger.error(f"Failed to update context: {str(e)}")

    def _clear_context(self, user):
        """Clear user context"""
        if user.id in self.user_contexts:
            del self.user_contexts[user.id]
            
        try:
            db_context = AIChatContext.objects.filter(user=user).first()
            if db_context:
                db_context.step = 'IDLE'
                db_context.action_type = None
                db_context.action_data = {}
                db_context.save()
        except Exception as e:
            logger.error(f"Failed to clear context: {str(e)}")

    def _find_closest_zone(self, zone_name: str) -> Optional[str]:
        """Find closest matching zone from cache"""
        zone_name_lower = zone_name.lower()
        
        # Direct match
        if zone_name_lower in self.zone_cache:
            return self.zone_cache[zone_name_lower]['name']
            
        # Partial match
        for cached_name, data in self.zone_cache.items():
            if zone_name_lower in cached_name or cached_name in zone_name_lower:
                return data['name']
                
        return None

    def _find_nearest_zone(self, lat: float, lon: float) -> Optional[str]:
        """Find nearest zone to coordinates"""
        if not lat or not lon:
            return None
            
        nearest = None
        min_dist = float('inf')
        
        for zone_name, data in self.zone_cache.items():
            if data['latitude'] and data['longitude']:
                dist = self._haversine(
                    lat, lon,
                    data['latitude'],
                    data['longitude']
                )
                if dist < min_dist:
                    min_dist = dist
                    nearest = data['name']
                    
        return nearest if min_dist < 5 else None  # Within 5km

    def _find_alternative_zones(self, current_zone, lat: float, lon: float) -> List[str]:
        """Find alternative zones"""
        alternatives = []
        
        zones = Zone.objects.filter(is_active=True).exclude(id=current_zone.id)
        
        for zone in zones:
            if zone.available_slots > 0:
                if lat and lon and zone.latitude and zone.longitude:
                    dist = self._haversine(lat, lon, float(zone.latitude), float(zone.longitude))
                    if dist < 3:  # Within 3km
                        alternatives.append(f"{zone.name} ({dist:.1f}km away)")
                else:
                    alternatives.append(zone.name)
                    
        return alternatives[:3]  # Return top 3

    def _calculate_zone_score(self, zone, distance: float) -> Tuple[float, List[str]]:
        """Calculate overall zone score for recommendations with descriptive factors"""
        score = 100
        justifications = []
        
        # Distance factor (closer is better) - Weighted @ 40%
        dist_impact = distance * 10
        score -= dist_impact
        justifications.append(f"Proximity analysis: {distance:.2f}km away (-{dist_impact:.1f} score impact).")
        
        # Availability factor - Weighted @ 30%
        if zone.available_slots > 0:
            avail_bonus = min(zone.available_slots, 10) * 2
            score += avail_bonus
            justifications.append(f"Capacity check: {zone.available_slots} spots available (+{avail_bonus} bonus).")
        else:
            score -= 50
            justifications.append("Capacity warning: Zone is currently full (-50 penalty).")
            
        # Price factor - Weighted @ 30%
        avg_rate_obj = Zone.objects.aggregate(Avg('hourly_rate'))['hourly_rate__avg'] or 1000
        avg_rate = float(avg_rate_obj)
        hourly_rate = float(zone.hourly_rate)
        
        if hourly_rate < avg_rate * 0.8:
            score += 20  # Cheaper
            justifications.append(f"Price analysis: {hourly_rate:,.0f} UGX/hr is below market average (+20 bonus).")
        elif hourly_rate > avg_rate * 1.2:
            score -= 10  # More expensive
            justifications.append(f"Price analysis: {hourly_rate:,.0f} UGX/hr is premium pricing (-10 impact).")
        else:
            justifications.append(f"Price analysis: {hourly_rate:,.0f} UGX/hr is within standard range.")
            
        return max(0, score), justifications

    def _generate_recommendation_reason(self, zone, distance: float, score: float) -> str:
        """Generate reason for recommendation"""
        reasons = []
        
        if distance < 1:
            reasons.append("very close to you")
        elif distance < 2:
            reasons.append("nearby")
            
        if zone.available_slots > 5:
            reasons.append("plenty of spots available")
        elif zone.available_slots > 0:
            reasons.append("some spots available")
            
        avg_rate = Zone.objects.aggregate(Avg('hourly_rate'))['hourly_rate__avg'] or 1000
        if zone.hourly_rate < avg_rate * 0.8:
            reasons.append("great value")
        elif zone.hourly_rate > avg_rate * 1.2:
            reasons.append("premium location")
            
        if reasons:
            return f"✨ {', '.join(reasons)}"
        return "👍 Good option"

    def _reason_violations(self, user, entities: Dict) -> Dict:
        """Reason about parking violations and fines"""
        result = {'count': 0, 'total': 0, 'violations': []}
        
        if user.is_authenticated:
            violations = Violation.objects.filter(vehicle__user=user, is_paid=False)
            result['count'] = violations.count()
            result['total'] = float(violations.aggregate(Sum('fine_amount'))['fine_amount__sum'] or 0)
            
            for v in violations:
                result['violations'].append({
                    'id': str(v.id),
                    'type': v.get_violation_type_display(),
                    'amount': float(v.fine_amount),
                    'zone': v.zone.name,
                    'date': v.created_at
                })
        return result

    def _reason_loyalty(self, user) -> Dict:
        """Reason about loyalty points and rewards"""
        result = {
            'points': 0,
            'tier': 'Bronze',
            'next_tier': 'Silver',
            'next_tier_points': 1000,
            'benefits': 'Start earning points with every parking session!'
        }
        
        if user.is_authenticated:
            account, created = LoyaltyAccount.objects.get_or_create(user=user)
            result['points'] = account.balance
            result['tier'] = account.tier
            
            # Simple tier logic
            tiers = {
                'Bronze': ('Silver', 1000, 'Earn 1 point per 1,000 UGX spent.'),
                'Silver': ('Gold', 5000, 'Earn 1.5 points per 1,000 UGX spent.'),
                'Gold': ('Platinum', 10000, 'Earn 2 points per 1,000 UGX spent + Priority Support.'),
                'Platinum': ('Max', 0, 'VIP Parking access + 3 points per 1,000 UGX!')
            }
            
            tier_info = tiers.get(account.tier)
            if tier_info:
                result['next_tier'] = tier_info[0]
                result['next_tier_points'] = max(0, tier_info[1] - account.lifetime_points)
                result['benefits'] = tier_info[2]
                
        return result

    def _generate_suggested_actions(self, user, response_text: str) -> List[Dict]:
        """Generate relevant UI action buttons based on AI response context"""
        actions = []
        response_lower = response_text.lower()
        
        if 'balance' in response_lower or 'wallet' in response_lower:
            actions.append({'label': 'Top Up Wallet', 'action': 'TOP_UP', 'color': 'green'})
            
        if 'parked' in response_lower or 'session' in response_lower:
            if 'active parking session found' in response_lower or "you're currently parked" in response_lower:
                actions.append({'label': 'End Parking', 'action': 'STOP_PARKING', 'color': 'red'})
            else:
                actions.append({'label': 'Find Parking', 'action': 'NAVIGATE_MAP', 'color': 'blue'})
                
        if 'violation' in response_lower or 'fine' in response_lower or 'ticket' in response_lower:
            actions.append({'label': 'Pay Fines', 'action': 'PAY_FINES', 'color': 'orange'})
            
        if 'points' in response_lower or 'loyalty' in response_lower:
            actions.append({'label': 'View Rewards', 'action': 'VIEW_REWARDS', 'color': 'purple'})

        if 'recommend' in response_lower or 'best parking' in response_lower:
            actions.append({'label': 'View on Map', 'action': 'NAVIGATE_MAP', 'color': 'blue'})

        if not actions:
            actions.append({'label': 'Check Balance', 'action': 'CHECK_BALANCE'})
            actions.append({'label': 'Find Parking', 'action': 'NAVIGATE_MAP'})

        return actions[:3]  # Limit to 3 suggestions

    def _generate_fallback_response(self, query: str) -> str:
        """Generate intelligent fallback response"""
        query_lower = query.lower()
        
        for key, answer in self.knowledge_base['common_questions'].items():
            if key.replace('_', ' ') in query_lower:
                return answer
                
        if any(w in query_lower for w in ['where', 'location', 'near']):
            return "To find parking near you, please enable location services or specify a zone name."
            
        return random.choice(self.response_templates['fallback'])

    def _find_closest_zone(self, name: str) -> Optional[str]:
        """Find the most similar zone name from cache"""
        name = name.lower().strip()
        if name in self.zone_cache:
            return self.zone_cache[name]['name']
            
        for zone_name in self.zone_cache:
            if name in zone_name or zone_name in name:
                return self.zone_cache[zone_name]['name']
        return None

    def _perform_sentiment_analysis(self, query: str) -> str:
        """Rule-based sentiment analysis to adjust AI personality"""
        query_lower = query.lower()
        negative_words = ['bad', 'awful', 'terrible', 'stupid', 'hate', 'fix', 'broken', 'error', 'wrong', 'frustrating', 'slow', 'worst']
        positive_words = ['good', 'great', 'awesome', 'amazing', 'happy', 'thanks', 'thank', 'help', 'nice', 'best']
        
        neg_count = sum(1 for w in negative_words if w in query_lower)
        pos_count = sum(1 for w in positive_words if w in query_lower)
        
        if neg_count > pos_count:
            return "APOLOGETIC"
        if pos_count > neg_count:
            return "ENTHUSIASTIC"
        return "NEUTRAL"

    def _calculate_zone_risk_score(self, zone_data: Dict) -> Dict:
        """Calculate security risk score based on historical and amenity data"""
        score = 0
        reasons = []
        
        if 'Security' in zone_data.get('amenities', []):
            score += 3
            reasons.append("Uniformed security presence")
        if 'Lighting' in zone_data.get('amenities', []):
            score += 2
            reasons.append("Well-lit at night")
        if 'CCTV' in zone_data.get('amenities', []):
            score += 4
            reasons.append("24/7 CCTV surveillance")
            
        return {
            'level': 'Low' if score > 6 else 'Medium' if score > 3 else 'High',
            'score': score,
            'reasons': reasons
        }

    def _reason_towing_status(self, plate: str) -> Dict:
        """Heuristic check for possible towing status (simulated logic)"""
        # In a real app, this would query an enforcement database
        return {
            'is_likely_towed': False,
            'reason': 'No active towing record found for this plate.',
            'next_steps': 'Check your last parking location or call +256 800 123 456.'
        }

    def _reason_loyalty_details(self, user) -> str:
        """Provide extra details on how the loyalty system works"""
        kb = self.knowledge_base['loyalty_tiers']
        response = "**Loyalty Tier Breakdown:**\n"
        for tier, info in kb.items():
            perks = ", ".join(info['perks'])
            response += f"• **{tier}**: {info['threshold']}+ points | {perks}\n"
        return response

    def _log_reasoning_trace(self, user, trace_data: Dict):
        """Log the internal thought process of the AI for auditing"""
        if settings.DEBUG:
            logger.debug(f"AI Reasoning Trace for {user.email}: {json.dumps(trace_data)}")
        
        # Optionally save to a model
        # AIChatContext.objects.create(user=user, metadata={'trace': trace_data})

    def _calculate_peak_pricing_adjustment(self, zone_obj) -> Tuple[float, str]:
        """Reason about dynamic pricing adjustments during peak hours"""
        now = timezone.now().hour
        kb_peaks = self.knowledge_base['peak_hours']
        
        for name, (start, end) in kb_peaks.items():
            if start <= now <= end:
                # 20% peak increase logic
                return 1.2, f"Standard rate + 20% {name.replace('_', ' ')} adjustment."
        return 1.0, "Standard hourly rate."

    def _reason_accessibility(self, zone_obj) -> str:
        """Provide detailed accessibility information for a zone"""
        policy = self.knowledge_base['common_questions']['disabled_parking']
        return f"**Accessibility at {zone_obj.name}:**\nThis zone includes dedicated disabled parking spots near the main exit. {policy}"

    def _perform_context_augmentation(self, user, context: Dict) -> Dict:
        """Add even more environmental and user context for deep reasoning"""
        aug_context = context.copy()
        now = timezone.now()
        
        # Add weather simulation (real app would use weather API)
        aug_context['weather'] = random.choice(['Sunny', 'Rainy', 'Cloudy'])
        aug_context['is_holiday'] = False # Real app check calendar
        
        if aug_context['weather'] == 'Rainy':
            aug_context['recommendation_boost'] = 'Indoor parking'
            
        return aug_context

    def _format_duration(self, duration: timedelta) -> str:
        """Format timedelta into readable string"""
        hours, remainder = divmod(int(duration.total_seconds()), 3600)
        minutes, _ = divmod(remainder, 60)
        
        if hours > 0:
            return f"{hours}h {minutes}m"
        return f"{minutes}m"

    def _haversine(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two points in kilometers"""
        R = 6371  # Earth radius in km
        d_lat = math.radians(lat2 - lat1)
        d_lon = math.radians(lon2 - lon1)
        a = (math.sin(d_lat / 2) ** 2 + 
             math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lon / 2) ** 2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c

class AIPolicyEncyclopedia:
    """
    A massive repository of Jambo Park rules, guidelines, and localized 
    knowledge, structured for deep AI reasoning.
    """
    def __init__(self):
        self.data = self._load_encyclopedia_data()

    def _load_encyclopedia_data(self) -> Dict:
        return {
            'SECTION_1_FINES': {
                'overdue': '5,000 UGX flat fee + hourly rate.',
                'clamping': 'Applicable after 3 unpaid fines.',
                'towing': 'Applicable for blocking emergency exits or 5+ fines.',
                'dispute_window': '48 hours from issuance.'
            },
            'SECTION_2_LOYALTY': {
                'points_per_ugx': '1 point per 1,000 UGX.',
                'tier_bronze': '0 - 1,000 points.',
                'tier_silver': '1,001 - 5,000 points.',
                'tier_gold': '5,001 - 10,000 points.',
                'tier_platinum': '10,001+ points.'
            },
            'SECTION_3_PAYMENTS': {
                'pesapal': 'Integrated for MTN, Airtel, and International Cards.',
                'wallet': 'Internal credit system with 0% transaction fees.',
                'withdrawals': 'Wallet balance cannot be withdrawn but can be used for any partner service.'
            },
            'SECTION_4_SAFETY': {
                'cctv': 'Active in all Plaza and Mall zones.',
                'officers': 'Available on-site from 6 AM to 1 AM.',
                'emergency_line': '+256 800 123 456'
            },
            'SECTION_5_CORPORATE': {
                'fleet_discount': '10% off for 10+ vehicles.',
                'billing': 'Monthly invoicing available for Platinum accounts.'
            }
        }

    def get_policy_summary(self, section: str) -> str:
        section_data = self.data.get(section.upper())
        if not section_data: return "Section not found."
        return "\n".join([f"• **{k.capitalize()}**: {v}" for k, v in section_data.items()])

class UserSentimentManager:
    """Manages AI personality based on user mood and interaction history"""
    def __init__(self):
        self.mood_threshold = 2.0
        
    def get_adjustment_phrase(self, sentiment: str) -> str:
        if sentiment == "APOLOGETIC":
            return "I sincerely apologize for the inconvenience. Let's get this resolved immediately. "
        if sentiment == "ENTHUSIASTIC":
            return "Happy to help with that! "
        return ""

class ParkingOptimizationEngine:
    """Advanced algorithms for recommending the 'ideal' parking spot"""
    def __init__(self, zone_cache: Dict):
        self.zones = zone_cache

    def get_optimized_recommendation(self, user_lat: float, user_lon: float, user_pref: Dict) -> Dict:
        """Deep optimization logic for multi-factor recommendations"""
        best_zone = None
        best_score = -1.0
        
        for name, data in self.zones.items():
            # Distance Weighting (40%)
            dist = self._calculate_dist(user_lat, user_lon, data['latitude'], data['longitude'])
            dist_score = (1 - min(dist / 5.0, 1.0)) * 40
            
            # Price Weighting (30%)
            price_score = (1 - (data['rate'] / 5000)) * 30
            
            # Availability Weighting (30%)
            avail_score = (data['available'] / data['capacity']) * 30 if data['capacity'] > 0 else 0
            
            total_score = dist_score + price_score + avail_score
            
            if total_score > best_score:
                best_score = total_score
                best_zone = data
                
        return {'zone': best_zone, 'score': best_score}

    def _calculate_dist(self, lat1, lon1, lat2, lon2):
        if not lat1 or not lon1 or not lat2 or not lon2: return 999
        R = 6371
        d_lat = math.radians(lat2 - lat1)
        d_lon = math.radians(lon2 - lon1)
        a = (math.sin(d_lat / 2) ** 2 + 
             math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(d_lon / 2) ** 2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        return R * c
