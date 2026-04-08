import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider } from './AuthContext';
import { PrivateRoute, BankDetailsGuard } from './RouteGuards';
import LandingPage from './pages/LandingPage';
import ApplyPage from './pages/ApplyPage';
import SuccessPage from './pages/SuccessPage';
import StatusPage from './pages/StatusPage';
import LoginPage from './pages/LoginPage';
import BankDetailsPage from './pages/BankDetailsPage';
import DashboardPage from './pages/DashboardPage';
import AddZonePage from './pages/AddZonePage';
import ManageZonesPage from './pages/ManageZonesPage';
import PricingRulesOverviewPage from './pages/PricingRulesOverviewPage';
import PricingRulesPage from './pages/PricingRulesPage';
import ZoneEditPage from './pages/ZoneEditPage';
import ChangePasswordPage from './pages/ChangePasswordPage';
import PrivacyPage from './pages/PrivacyPage';
import TermsPage from './pages/TermsPage';
import HowItWorksPage from './pages/HowItWorksPage';
import './index.css';

export default function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          {/* Public */}
          <Route path="/" element={<LandingPage />} />
          <Route path="/apply" element={<ApplyPage />} />
          <Route path="/apply/success" element={<SuccessPage />} />
          <Route path="/status" element={<StatusPage />} />
          <Route path="/login" element={<LoginPage />} />
          <Route path="/privacy" element={<PrivacyPage />} />
          <Route path="/terms" element={<TermsPage />} />
          <Route path="/how-it-works" element={<HowItWorksPage />} />

          {/* Auth required — bank details gate */}
          <Route path="/bank-details" element={
            <PrivateRoute><BankDetailsPage /></PrivateRoute>
          } />

          {/* Auth + bank details required */}
          <Route path="/dashboard" element={
            <BankDetailsGuard><DashboardPage /></BankDetailsGuard>
          } />
          <Route path="/add-zone" element={
            <BankDetailsGuard><AddZonePage /></BankDetailsGuard>
          } />
          <Route path="/manage-zones" element={
            <BankDetailsGuard><ManageZonesPage /></BankDetailsGuard>
          } />
          <Route path="/pricing-rules" element={
            <BankDetailsGuard><PricingRulesOverviewPage /></BankDetailsGuard>
          } />
          <Route path="/zones/:zoneId/pricing-rules" element={
            <BankDetailsGuard><PricingRulesPage /></BankDetailsGuard>
          } />
          <Route path="/zones/:zoneId/edit" element={
            <BankDetailsGuard><ZoneEditPage /></BankDetailsGuard>
          } />
          <Route path="/change-password" element={
            <BankDetailsGuard><ChangePasswordPage /></BankDetailsGuard>
          } />

          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}
