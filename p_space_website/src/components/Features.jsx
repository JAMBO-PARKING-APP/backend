import React from 'react';
import { motion } from 'framer-motion';
import { Map, CreditCard, ShieldAlert, QrCode, ClipboardCheck, BarChart3 } from 'lucide-react';

const FeatureCard = ({ icon: Icon, title, description, delay }) => (
  <motion.div 
    initial={{ opacity: 0, y: 20 }}
    whileInView={{ opacity: 1, y: 0 }}
    viewport={{ once: true }}
    transition={{ duration: 0.5, delay }}
    className="p-8 rounded-[32px] bg-surface hover:bg-white hover:shadow-xl transition-all duration-300 border border-transparent hover:border-gray-100"
  >
    <div className="w-14 h-14 rounded-2xl premium-gradient flex items-center justify-center text-white mb-6">
      <Icon size={28} />
    </div>
    <h3 className="text-xl font-bold text-text mb-3">{title}</h3>
    <p className="text-text-muted text-sm leading-relaxed">{description}</p>
  </motion.div>
);

const Features = () => {
  const features = [
    {
      icon: Map,
      title: "Live Zone Map",
      description: "Real-time visualization of parking zones with dynamic availability indicators."
    },
    {
      icon: CreditCard,
      title: "Managed Wallet",
      description: "Secure digital wallet with support for MTN/Airtel Money, Stripe, and Pesapal."
    },
    {
      icon: ShieldAlert,
      title: "Geofence Alerts",
      description: "Smart notifications if you move away from your active parking session."
    },
    {
      icon: QrCode,
      title: "QR Verification",
      description: "Digital QR codes for instant session verification by parking officers."
    },
    {
      icon: ClipboardCheck,
      title: "Digital Enforcement",
      description: "Evidence-first violation logging with triple-photo proof and GPS tagging."
    },
    {
      icon: BarChart3,
      title: "Governance Dashboard",
      description: "Real-time revenue heatmaps and policy-engine for municipal managers."
    }
  ];

  return (
    <section id="features" className="section-padding bg-white">
      <div className="container">
        <div className="text-center max-w-3xl mx-auto mb-16">
          <h2 className="text-4xl md:text-5xl font-extrabold text-text mb-4">
            Everything you need for <br />
            <span className="text-primary">Seamless Parking.</span>
          </h2>
          <p className="text-lg text-text-muted">
            Space Park bridges the gap between drivers, officers, and administrators with a unified real-time data mesh.
          </p>
        </div>

        <div className="grid md:grid-cols-3 gap-8">
          {features.map((f, i) => (
            <FeatureCard 
              key={i}
              icon={f.icon}
              title={f.title}
              description={f.description}
              delay={i * 0.1}
            />
          ))}
        </div>
      </div>
    </section>
  );
};

export default Features;
