from django.template import Library, Node, TemplateSyntaxError
from django.templatetags.static import static as django_static

register = Library()

@register.tag(name='admin_static')
@register.tag(name='static')
def do_static(parser, token):
    from django.templatetags.static import do_static as django_do_static
    return django_do_static(parser, token)

class IfEqualNode(Node):
    def __init__(self, var1, var2, nodelist_true, nodelist_false, negate):
        self.var1, self.var2 = var1, var2
        self.nodelist_true, self.nodelist_false = nodelist_true, nodelist_false
        self.negate = negate

    def render(self, context):
        val1 = self.var1.resolve(context, ignore_failures=True)
        val2 = self.var2.resolve(context, ignore_failures=True)
        if (self.negate and val1 != val2) or (not self.negate and val1 == val2):
            return self.nodelist_true.render(context)
        return self.nodelist_false.render(context)

def do_ifequal(parser, token, negate):
    bits = token.split_contents()
    if len(bits) != 3:
        raise TemplateSyntaxError("%r takes two arguments" % bits[0])
    end_tag = 'end' + bits[0]
    nodelist_true = parser.parse(('else', end_tag))
    token = parser.next_token()
    if token.contents == 'else':
        nodelist_false = parser.parse((end_tag,))
        parser.delete_first_token()
    else:
        nodelist_false = parser.compile_nodelist()
    val1 = parser.compile_filter(bits[1])
    val2 = parser.compile_filter(bits[2])
    return IfEqualNode(val1, val2, nodelist_true, nodelist_false, negate)

@register.tag
def ifequal(parser, token):
    return do_ifequal(parser, token, False)

@register.tag
def ifnotequal(parser, token):
    return do_ifequal(parser, token, True)
