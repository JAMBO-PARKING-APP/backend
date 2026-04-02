from django.conf import settings
from apps.common.models import Country
import logging

logger = logging.getLogger(__name__)

class CountryTermsService:
    
    @staticmethod
    def get_country_specific_terms(country):
        """Get country-specific terms and conditions"""
        if not country:
            return CountryTermsService._get_default_terms()
        
        country_terms_map = {
            'UG': {
                'title': 'Uganda Parking Terms',
                'additional_clauses': [
                    'All parking must comply with Uganda Traffic Regulations',
                    'Users must respect Kampala City Council parking guidelines',
                    'Payment in Ugandan Shillings (UGX) only',
                    'Valid driver\'s license required for all users'
                ],
                'privacy_note': 'Data handled according to Uganda Data Protection Act 2019',
                'dispute_resolution': 'Disputes handled under Ugandan law'
            },
            'KE': {
                'title': 'Kenya Parking Terms',
                'additional_clauses': [
                    'Compliance with Kenya Traffic Act required',
                    'Nairobi County parking regulations apply',
                    'Payment in Kenyan Shillings (KES) only',
                    'Vehicle registration mandatory'
                ],
                'privacy_note': 'Data processed under Kenya Data Protection Act 2019',
                'dispute_resolution': 'Disputes governed by Kenyan law'
            },
            'TZ': {
                'title': 'Tanzania Parking Terms',
                'additional_clauses': [
                    'Must follow Tanzania Road Traffic Act',
                    'Dar es Salaam parking rules apply',
                    'Payment in Tanzanian Shillings (TZS) only',
                    'Local vehicle registration required'
                ],
                'privacy_note': 'Data handled per Tanzania Data Protection Act',
                'dispute_resolution': 'Tanzanian law applies'
            },
            'RW': {
                'title': 'Rwanda Parking Terms',
                'additional_clauses': [
                    'Rwanda Traffic Regulations must be followed',
                    'Kigali City parking guidelines apply',
                    'Payment in Rwandan Francs (RWF) only',
                    'Valid vehicle insurance required'
                ],
                'privacy_note': 'Data protected under Rwanda Data Protection Law',
                'dispute_resolution': 'Rwandan law governs disputes'
            },
            'GH': {
                'title': 'Ghana Parking Terms',
                'additional_clauses': [
                    'Ghana Road Traffic Regulations compliance required',
                    'Accra Metropolitan Assembly parking rules',
                    'Payment in Ghanaian Cedis (GHS) only',
                    'Vehicle roadworthiness certificate required'
                ],
                'privacy_note': 'Data Protection Act Ghana 2012 applies',
                'dispute_resolution': 'Ghanaian law applies'
            },
            'NG': {
                'title': 'Nigeria Parking Terms',
                'additional_clauses': [
                    'Nigerian Road Traffic Act compliance mandatory',
                    'Lagos State parking regulations apply',
                    'Payment in Nigerian Naira (NGN) only',
                    'Valid vehicle inspection certificate required'
                ],
                'privacy_note': 'Nigerian Data Protection Regulation 2019 applies',
                'dispute_resolution': 'Nigerian law governs disputes'
            },
        }
        
        return country_terms_map.get(country.iso_code, CountryTermsService._get_default_terms())
    
    @staticmethod
    def _get_default_terms():
        """Default terms for countries without specific regulations"""
        return {
            'title': 'General Parking Terms',
            'additional_clauses': [
                'Compliance with local parking regulations required',
                'Valid driver\'s license mandatory',
                'Proper vehicle registration required',
                'Payment in local currency only'
            ],
            'privacy_note': 'Data handled according to applicable privacy laws',
            'dispute_resolution': 'Local laws and regulations apply'
        }
    
    @staticmethod
    def get_privacy_policy_for_country(country):
        """Get country-specific privacy policy"""
        base_policy = {
            'data_collection': 'We collect personal information necessary for parking services',
            'data_usage': 'Your data is used to provide parking services and improve user experience',
            'data_sharing': 'We do not sell your personal information to third parties',
            'data_retention': 'Data is retained only as long as necessary for service provision',
            'user_rights': 'You have the right to access, correct, and delete your data'
        }
        
        if country:
            country_specific = {
                'UG': {
                    'legal_basis': 'Data Protection Act 2019',
                    'regulatory_authority': 'Uganda Data Protection Office',
                    'cross_border_transfer': 'Data transfers comply with Ugandan regulations'
                },
                'KE': {
                    'legal_basis': 'Data Protection Act 2019',
                    'regulatory_authority': 'Office of the Data Protection Commissioner',
                    'cross_border_transfer': 'Transfers follow Kenyan data protection laws'
                },
                'TZ': {
                    'legal_basis': 'Data Protection Act',
                    'regulatory_authority': 'Personal Data Protection Commission',
                    'cross_border_transfer': 'Complies with Tanzanian data laws'
                },
            }
            
            if country.iso_code in country_specific:
                base_policy.update(country_specific[country.iso_code])
        
        return base_policy
    
    @staticmethod
    def format_terms_for_display(country, language='en'):
        """Format terms for display in specific language and country"""
        terms = CountryTermsService.get_country_specific_terms(country)
        
        # Language-specific formatting
        translations = {
            'sw': {
                'title': 'Masharti ya Maegesho',
                'compliance_note': 'Lazima ufuate sheria za maegesho za nchi yako',
                'privacy_note': 'Data yako inalindwa kulingana na sheria za nchi yako',
                'currency_note': 'Malipo katika sarafi ya ndani tu'
            },
            'fr': {
                'title': 'Conditions de Stationnement',
                'compliance_note': 'Vous devez respecter les réglementations locales',
                'privacy_note': 'Vos données sont protégées selon les lois locales',
                'currency_note': 'Paiements en devise locale uniquement'
            }
        }
        
        if language in translations:
            terms.update(translations[language])
        
        return terms
