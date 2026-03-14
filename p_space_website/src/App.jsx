import React, { useEffect } from 'react'
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom'
import Header from './components/Header'
import HomePage from './pages/HomePage'
import TermsPage from './pages/TermsPage'
import PrivacyPage from './pages/PrivacyPage'
import Footer from './components/Footer'
import PartnerLoginPage from './pages/PartnerLoginPage'
import PartnerDashboard from './pages/PartnerDashboard'
import PartnerApplyPage from './pages/PartnerApplyPage'
// Scroll to top on route change
function ScrollToTop() {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);
  return null;
}

function App() {
  return (
    <Router>
      <ScrollToTop />
      <div className="min-h-screen">
        <Header />
        <Routes>
          <Route path="/" element={<HomePage />} />
          <Route path="/terms" element={<TermsPage />} />
          <Route path="/privacy" element={<PrivacyPage />} />
          <Route path="/partner/login" element={<PartnerLoginPage />} />
          <Route path="/partner/dashboard" element={<PartnerDashboard />} />
          <Route path="/partner/apply" element={<PartnerApplyPage />} />
        </Routes>
        <Footer />
      </div>
    </Router>
  )
}

export default App
