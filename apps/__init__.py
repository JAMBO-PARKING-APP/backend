import sys
import logging

logger = logging.getLogger(__name__)

try:
    if sys.version_info >= (3, 12):
        # Patch for Context.__copy__ bugs in older Django versions when running on Python 3.12+
        # This addresses "AttributeError: 'super' object has no attribute 'dicts'"
        # and other copy-related issues caused by PEP 667 and super() changes.
        # Reference: https://code.djangoproject.com/ticket/35471
        
        from django.template import context
        import copy

        def robust_base_copy(self):
            # Bypass super().__copy__() which might return a super object in Py3.13+
            new_obj = self.__class__.__new__(self.__class__)
            new_obj.dicts = self.dicts[:]
            return new_obj

        def robust_context_copy(self):
            # Generic copy that works correctly for Context/RequestContext
            new_obj = self.__class__.__new__(self.__class__)
            # Manual dictionary update is safer than copy.copy(self) in some contexts
            new_obj.__dict__.update(self.__dict__)
            new_obj.dicts = self.dicts[:]
            return new_obj

        # Apply patches only if they exist and are using the old problematic logic
        if hasattr(context.BaseContext, '__copy__'):
             context.BaseContext.__copy__ = robust_base_copy
        if hasattr(context.Context, '__copy__'):
             context.Context.__copy__ = robust_context_copy
            
        logger.info("Patched Django Context for Python 3.12+ compatibility")
except ImportError:
    # Django might not be available in all environments (e.g. during migrations/setup)
    pass
except Exception as e:
    logger.error(f"Failed to patch Django Context: {e}")
