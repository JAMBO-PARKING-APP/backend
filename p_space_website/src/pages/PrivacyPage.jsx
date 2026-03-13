import React from 'react';
import { motion } from 'framer-motion';

const PrivacyPage = () => {
  return (
    <div className="section-padding pt-32">
      <div className="container max-w-4xl">
        <motion.div 
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="glass-morphism p-10 md:p-16 rounded-[40px]"
        >
          <h1 className="text-4xl md:text-5xl font-black mb-8">Privacy Policy</h1>
          <p className="text-text-muted mb-8 italic">Last Updated: March 13, 2026</p>

          <section className="space-y-8 text-text text-lg leading-relaxed">
            <div>
              <h2 className="text-2xl font-bold mb-4">1. Information We Collect</h2>
              <p>We collect location data to provide zone search services, vehicle details for identification, and payment information for transaction processing. We also collect device identifiers for push notification routing.</p>
            </div>

            <div>
              <h2 className="text-2xl font-bold mb-4">2. How We Use Data</h2>
              <p>Your data is used to facilitate parking sessions, prevent fraud, and improve city mobility analytics. We do not sell your personal identification information to third parties.</p>
            </div>

            <div>
              <h2 className="text-2xl font-bold mb-4">3. Location Services</h2>
              <p>Real-time location is required for geofence alerts (reminding you to end a session if you leave the area). You can opt out of location services, but the app's functionality will be limited.</p>
            </div>

            <div>
              <h2 className="text-2xl font-bold mb-4">4. Data Security</h2>
              <p>We use enterprise-grade AES-256 encryption at rest and TLS 1.3 for all data in transit. Financial data is tokenized and never stored on our servers.</p>
            </div>
          </section>
        </motion.div>
      </div>
    </div>
  );
};

export default PrivacyPage;
