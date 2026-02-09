from django.urls import path
from . import views

urlpatterns = [
    # Dashboard
    path('', views.DashboardView.as_view(), name='dashboard'),
    
    # Authentication
    path('login/', views.LoginView.as_view(), name='login'),
    path('logout/', views.LogoutView.as_view(), name='logout'),
    
    # User Management
    path('users/', views.UserListView.as_view(), name='user-list'),
    path('users/create/', views.UserCreateView.as_view(), name='user-create'),
    path('users/<uuid:pk>/edit/', views.UserUpdateView.as_view(), name='user-edit'),
    
    # Vehicle Management
    path('vehicles/', views.VehicleListView.as_view(), name='vehicle-list'),
    path('vehicles/<uuid:pk>/', views.VehicleDetailView.as_view(), name='vehicle-detail'),
    
    # Zone Management
    path('zones/', views.ZoneListView.as_view(), name='zone-list'),
    path('zones/map/', views.ZoneMapView.as_view(), name='zone-map'),
    path('zones/create/', views.ZoneCreateView.as_view(), name='zone-create'),
    path('zones/<uuid:pk>/', views.ZoneDetailView.as_view(), name='zone-detail'),
    path('zones/<uuid:pk>/edit/', views.ZoneUpdateView.as_view(), name='zone-edit'),
    path('zones/<uuid:pk>/diagram/', views.ZoneDiagramView.as_view(), name='zone-diagram'),
    
    # Session Management
    path('sessions/', views.SessionListView.as_view(), name='session-list'),
    
    # Payment Management
    path('payments/', views.PaymentListView.as_view(), name='payment-list'),
    
    # Violation Management
    path('violations/', views.ViolationListView.as_view(), name='violation-list'),
    
    # AJAX Endpoints
    path('ajax/check-plate/', views.CheckPlateAjaxView.as_view(), name='check-plate-ajax'),
    path('ajax/user-search/', views.UserSearchAjaxView.as_view(), name='user-search-ajax'),
    path('ajax/vehicle-by-plate/', views.VehicleByPlateAjaxView.as_view(), name='vehicle-by-plate-ajax'),
    path('ajax/slot/create/', views.SlotCreateAjaxView.as_view(), name='slot-create-ajax'),
    path('ajax/slot/update/', views.SlotUpdateAjaxView.as_view(), name='slot-update-ajax'),
    path('ajax/slot/delete/', views.SlotDeleteAjaxView.as_view(), name='slot-delete-ajax'),
    path('ajax/slot/delete-all/', views.SlotDeleteAllAjaxView.as_view(), name='slot-delete-all-ajax'),
    path('ajax/boundary/create/', views.BoundaryCreateAjaxView.as_view(), name='boundary-create-ajax'),
    path('ajax/boundary/update/', views.BoundaryUpdateAjaxView.as_view(), name='boundary-update-ajax'),
    path('ajax/boundary/delete/', views.BoundaryDeleteAjaxView.as_view(), name='boundary-delete-ajax'),
    path('ajax/entrance/create/', views.EntranceCreateAjaxView.as_view(), name='entrance-create-ajax'),
    path('ajax/entrance/delete/', views.EntranceDeleteAjaxView.as_view(), name='entrance-delete-ajax'),
    path('ajax/drivepath/create/', views.DrivePathCreateAjaxView.as_view(), name='drivepath-create-ajax'),
    path('ajax/drivepath/update/', views.DrivePathUpdateAjaxView.as_view(), name='drivepath-update-ajax'),
    path('ajax/drivepath/delete/', views.DrivePathDeleteAjaxView.as_view(), name='drivepath-delete-ajax'),
    path('ajax/zones/<uuid:zone_id>/live-status/', views.ZoneLiveStatusAjaxView.as_view(), name='zone-live-status-ajax'),
]