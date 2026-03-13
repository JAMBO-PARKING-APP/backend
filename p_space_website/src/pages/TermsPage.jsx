import React from 'react';
import { motion } from 'framer-motion';

const TermsPage = () => {
  return (
    <div className="section-padding pt-32">
      <div className="container max-w-4xl">
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="glass-morphism p-10 md:p-16 rounded-[40px]"
        >
          <h1 className="text-4xl md:text-5xl font-black mb-8">Terms & Conditions</h1>
          <p className="text-text-muted mb-8 italic">Last Updated: March 13, 2026</p>

          <section className="space-y-8 text-text text-lg leading-relaxed">
            <div>
              <h2 className="text-2xl font-bold mb-4">1. Acceptance of Terms</h2>
              <p>By accessing and using the Space Park application ("the App"), you agree to be bound by these Terms and Conditions. If you do not agree to these terms, please do not use the service.</p>
            </div>

            <div>
              <h2 className="text-2xl font-bold mb-4">2. Service Description</h2>
              <p>Space Park provides a digital platform connecting parking space owners with drivers. We facilitate the finding, booking, and payment of parking sessions but do not own the physical parking infrastructure.</p>
            </div>

            <div>
              <h2 className="text-2xl font-bold mb-4">3. User Obligations</h2>
              <p>Users must provide accurate information, follow all local traffic laws, and pay the required fees for their parking sessions. Failure to vacate a spot after session expiry may result in enforcement actions by municipal authorities.</p>
            </div>

            <div>
              <h2 className="text-2xl font-bold mb-4">4. Payments & Refunds</h2>
              <p>All payments are processed through secure third-party gateways. Refunds for early departure are prorated by the minute and credited back to your digital wallet instantly.</p>
            </div>

            <div>
              <h2 className="text-2xl font-bold mb-4">5. Liability</h2>
              <p>Space Park is not responsible for theft, damage, or accidents occurring within the parking zones. Users park at their own risk.</p>
            </div>
          </section>
        </motion.div>
      </div>
    </div>
  );
};

export default TermsPage;
