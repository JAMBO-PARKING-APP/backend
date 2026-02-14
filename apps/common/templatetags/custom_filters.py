from django import template

register = template.Library()


@register.filter
def replace(value, arg):
    """
    Replace all instances of arg with an empty string in value.
    Usage: {{ value|replace:"substring" }}
    Or replace one character with another: {{ value|replace:"old, new" }}
    """
    if ',' in str(arg):
        old, new = arg.split(',', 1)
        return str(value).replace(old.strip(), new.strip())
    else:
        return str(value).replace(str(arg), '')


@register.filter
def underscore_to_space(value):
    """
    Replace underscores with spaces and apply title case.
    Usage: {{ value|underscore_to_space }}
    Example: "check_plate" -> "Check Plate"
    """
    return str(value).replace('_', ' ').title()
