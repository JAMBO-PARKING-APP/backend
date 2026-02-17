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
                r'\b(is\s*there\s*parking|parking\s*near\s*me|closest\s*(parking|zone))\b'
            ],
            IntentType.PRICING_INFO: [
                r'\b(price|cost|rate|how\s*much|charge|fee|tariff|pricing|expensive|cheap|affordable)\b',
                r"\b(what'?s\s*the\s*(price|rate)|parking\s*(rates?|costs?)|hourly\s*rate)\b"
            ],
            IntentType.VEHICLE_INFO: [
                r'\b(vehicle|car|auto|truck|bike|motorcycle|plate|registration|my\s*cars?|registered\s*vehicles|added\s*vehicles)\b',
                r'\b(show\s*(vehicles|cars)|list\s*vehicles|what\s*vehicles)\b'
            ],
            IntentType.PAYMENT_HELP: [
                r'\b(payment|pay|how\s*to\s*pay|mobile\s*money|mtn|airtel|pesapal|card|credit\s*card|debit\s*card|method|option)\b',
                r'\b(payment\s*(methods?|options?)|accepted\s*payments|ways?\s*to\s*pay)\b'
            ],
            IntentType.ZONE_INFO: [
                r'\b(tell\s*me\s*about|info\s*on|details?\s*for|what\s*is)\s*([a-zA-Z0-9\s]+)\s*(zone|area)?\b',
                r'\b(zone|area|location)\s*([a-zA-Z0-9\s]+)\b'
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
            EntityType.DURATION: r'\b(\d+)\s*(hours?|hrs?|minutes?|mins?|seconds?|secs?)\b'
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
            'availability_prediction': [
                "Based on historical data, {zone} is currently **{trend}**.\n{prediction}\n\nBest time to park: **{best_time}**",
                "Parking availability prediction for {zone}:\n• Current: {current_status}\n• Trend: {trend}\n• Best time: {best_time}"
            ]
        }

    def _initialize_knowledge_base(self) -> Dict:
        """Initialize knowledge base for reasoning"""
        return {
            'peak_hours': {
                'morning': (7, 9),
                'lunch': (12, 14),
                'evening': (17, 19)
            },
            'average_session_duration': timedelta(hours=2),
            'topup_suggestions': [5000, 10000, 20000, 50000],
            'common_questions': {
                'how_to_park': "To start parking, just say 'Start parking at [zone name]' or share your location for nearby options.",
                'payment_methods': "We accept Mobile Money (MTN/Airtel), Cards, and Wallet payments. Wallet is fastest!",
                'refund_policy': "Unused time is automatically refunded to your wallet when you end a session early."
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
            logger.error(f"AI Service error: {str(e)}")
            return "I encountered an error processing your request. Please try again or contact support."

    def _process_single_intent(self, user, query: str, lat: float, lon: float) -> str:
        """Process a single intent with full reasoning pipeline"""
        
        # Step 1: Classify intent with confidence scoring
        intent, confidence = self._classify_intent(query)
        
        # Step 2: Extract entities
        entities = self._extract_entities(query)
        
        # Step 3: Gather context
        context = self._gather_context(user, intent, entities)
        
        # Step 4: Apply reasoning
        reasoning_result = self._apply_reasoning(user, intent, entities, context, lat, lon)
        
        # Step 5: Generate response
        response = self._generate_response(intent, reasoning_result, user, query)
        
        # Step 6: Update context memory
        self._update_context(user, intent, entities, response, reasoning_result)
        
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
            reasoning_result = self._reason_recommendation(user, entities, context, lat, lon)
            
        elif intent == IntentType.PREDICTION:
            reasoning_result = self._reason_prediction(user, entities, context)
            
        return reasoning_result

    def _reason_balance(self, user, context: Dict) -> Dict:
        """Reason about wallet balance"""
        result = {
            'balance': context['user_history']['balance'] if user.is_authenticated else 0,
            'suggestion': '',
            'can_park': False,
            'recommended_topup': None
        }
        
        if user.is_authenticated:
            # Check if balance is sufficient for typical parking
            avg_cost = Zone.objects.aggregate(Avg('hourly_rate'))['hourly_rate__avg'] or 1000
            typical_session_cost = avg_cost * 2  # Assume 2-hour session
            
            if result['balance'] < typical_session_cost:
                result['suggestion'] = "Your balance is low for a typical parking session."
                result['recommended_topup'] = int(typical_session_cost * 1.5)  # Recommend 50% more
                result['can_park'] = False
            else:
                result['suggestion'] = "You have sufficient balance for parking."
                result['can_park'] = True
                
        return result

    def _reason_session(self, user, context: Dict) -> Dict:
        """Reason about active parking session"""
        result = {
            'has_active': False,
            'session_data': None,
            'suggestion': ''
        }
        
        if user.is_authenticated:
            active = ParkingSession.objects.filter(
                vehicle__user=user, 
                status='active'
            ).select_related('zone', 'vehicle').first()
            
            if active:
                now = timezone.now()
                elapsed = now - active.created_at
                remaining = active.planned_end_time - now
                
                cost_so_far = active.zone.hourly_rate * (elapsed.total_seconds() / 3600)
                
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
                    
        return result

    def _reason_start_parking(self, user, entities: Dict, context: Dict, lat: float, lon: float) -> Dict:
        """Reason about starting a parking session"""
        result = {
            'zone': None,
            'vehicle': None,
            'can_start': False,
            'issues': [],
            'alternatives': [],
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
        if user.wallet_balance < (zone_obj.hourly_rate if zone_obj else 1000):
            result['issues'].append("Insufficient balance")
            
        return result

    def _reason_parking_info(self, user, entities: Dict, context: Dict, lat: float, lon: float) -> Dict:
        """Reason about parking information and availability"""
        result = {
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
                        zones_with_dist.append({
                            'zone': zone,
                            'distance': dist,
                            'available': zone.available_slots,
                            'rate': zone.hourly_rate,
                            'score': self._calculate_zone_score(zone, dist)
                        })
            
            # Sort by score
            zones_with_dist.sort(key=lambda x: x['score'], reverse=True)
            result['nearby_zones'] = zones_with_dist[:5]
            
            # Generate summary
            available_count = sum(1 for z in zones_with_dist if z['available'] > 0)
            total_zones = len(zones_with_dist)
            
            if available_count == 0:
                result['summary'] = "All nearby zones are currently full."
            elif available_count < total_zones / 2:
                result['summary'] = "Parking is limited in your area."
            else:
                result['summary'] = f"Found {available_count} zones with available parking."
                
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
            rates = [z.hourly_rate for z in zones]
            result['average_rate'] = sum(rates) / len(rates)
            result['min_rate'] = min(rates)
            result['max_rate'] = max(rates)
            
            # Group by price range
            result['zones'] = [
                {
                    'name': z.name,
                    'rate': z.hourly_rate,
                    'relative_price': 'premium' if z.hourly_rate > result['average_rate'] * 1.2 else 
                                     'budget' if z.hourly_rate < result['average_rate'] * 0.8 else 'standard'
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
                value_score = popularity / (zone.hourly_rate / 1000)  # Normalized score
                
                result['comparisons'].append({
                    'zone': zone.name,
                    'rate': zone.hourly_rate,
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
                    score += (1 - (zone.hourly_rate / 5000)) * 5  # Price factor (0-5)
                    
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
            
        elif intent == IntentType.START_PARKING:
            if reasoning_result['can_start']:
                zone = reasoning_result['zone']
                vehicle = reasoning_result['vehicle']
                return f"Ready to start parking at **{zone.name}** with vehicle **{vehicle.license_plate}**?\nRate: {zone.hourly_rate:,.0f} UGX/hour.\nReply 'Yes' to confirm or 'No' to cancel."
            else:
                issues = reasoning_result['issues']
                if issues:
                    return f"Unable to start parking: {', '.join(issues)}"
                return "I need more information to help you start parking. Which zone would you like to park in?"
                
        elif intent == IntentType.PARKING_INFO:
            if reasoning_result['nearby_zones']:
                response = f"{reasoning_result['summary']}\n\n"
                for idx, zone_data in enumerate(reasoning_result['nearby_zones'], 1):
                    zone = zone_data['zone']
                    response += f"{idx}. **{zone.name}** - {zone_data['distance']:.1f}km\n"
                    response += f"   🅿️ {zone.available_slots}/{zone.total_slots} spots\n"
                    response += f"   💰 {zone.hourly_rate:,.0f} UGX/hr\n"
                return response
            return "No parking zones found nearby."
            
        elif intent == IntentType.PRICING_INFO:
            data = reasoning_result
            response = f"Parking rates range from **{data['min_rate']:,.0f}** to **{data['max_rate']:,.0f} UGX/hour**.\n"
            response += f"Average rate: **{data['average_rate']:,.0f} UGX/hour**\n\n"
            response += "Price categories:\n"
            
            for zone in data['zones']:
                emoji = "💰💰💰" if zone['relative_price'] == 'premium' else "💰💰" if zone['relative_price'] == 'standard' else "💰"
                response += f"{emoji} {zone['name']}: {zone['rate']:,.0f} UGX/hr\n"
            return response
            
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
                response = "Based on your location and preferences, I recommend:\n\n"
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
                
            # Calculate costs
            planned_end = timezone.now() + timedelta(hours=1)
            estimated_cost = zone.hourly_rate
            
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
                    'vehicle_id': vehicle_id
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

    def _calculate_zone_score(self, zone, distance: float) -> float:
        """Calculate overall zone score for recommendations"""
        score = 100
        
        # Distance factor (closer is better)
        score -= distance * 10
        
        # Availability factor
        if zone.available_slots > 0:
            score += min(zone.available_slots, 10) * 2
        else:
            score -= 50
            
        # Price factor
        avg_rate = Zone.objects.aggregate(Avg('hourly_rate'))['hourly_rate__avg'] or 1000
        if zone.hourly_rate < avg_rate * 0.8:
            score += 20  # Cheaper
        elif zone.hourly_rate > avg_rate * 1.2:
            score -= 10  # More expensive
            
        return max(0, score)

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

    def _generate_fallback_response(self, query: str) -> str:
        """Generate intelligent fallback response"""
        # Check if it's a common question
        query_lower = query.lower()
        
        for key, answer in self.knowledge_base['common_questions'].items():
            if key.replace('_', ' ') in query_lower:
                return answer
                
        # Check for vague location queries
        if any(w in query_lower for w in ['where', 'location', 'near']):
            return "To find parking near you, please enable location services or specify a zone name."
            
        # Default fallback
        return "I'm not sure I understand. You can ask me about:\n" + \
               "• Starting/stopping parking\n" + \
               "• Wallet balance\n" + \
               "• Active sessions\n" + \
               "• Nearby parking\n" + \
               "• Parking rates\n" + \
               "• Payment methods\n\n" + \
               "How can I help you today?"

    def _format_duration(self, duration: timedelta) -> str:
        """Format timedelta into readable string"""
        total_seconds = int(duration.total_seconds())
        
        if total_seconds < 0:
            return "Expired"
            
        hours = total_seconds // 3600
        minutes = (total_seconds % 3600) // 60
        
        if hours > 0:
            return f"{hours}h {minutes}m"
        else:
            return f"{minutes}m"

    def _haversine(self, lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two points in kilometers"""
        R = 6371  # Earth's radius in kilometers
        
        dlat = math.radians(lat2 - lat1)
        dlon = math.radians(lon2 - lon1)
        
        a = (math.sin(dlat / 2) ** 2 + 
             math.cos(math.radians(lat1)) * 
             math.cos(math.radians(lat2)) * 
             math.sin(dlon / 2) ** 2)
             
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        
        return R * c