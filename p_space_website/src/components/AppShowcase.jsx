import React from 'react';
import { motion } from 'framer-motion';

const screenshots = [
  { src: '/assets/WhatsApp Image 2026-03-13 at 3.50.34 PM (3).jpeg', title: 'Home View' },
  { src: '/assets/WhatsApp Image 2026-03-13 at 3.50.33 PM.jpeg', title: 'Wallet & Pricing' },
  { src: '/assets/WhatsApp Image 2026-03-13 at 3.50.34 PM (1).jpeg', title: 'Active Session' },
  { src: '/assets/WhatsApp Image 2026-03-13 at 3.50.35 PM.jpeg', title: 'Enforcement Tool' },
];

const AppShowcase = () => {
  return (
    <section id="marketplace" className="section-padding bg-surface overflow-hidden">
      <div className="container">
        <div className="text-center mb-16">
          <h2 className="text-4xl font-black mb-4">Designed for <span className="text-primary italic">Simplicity</span></h2>
          <p className="text-text-muted max-w-2xl mx-auto">Explore the intuitive interface that makes urban parking a breeze for both drivers and municipal officers.</p>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-6">
          {screenshots.map((item, i) => (
            <motion.div 
              key={i}
              whileHover={{ y: -10 }}
              initial={{ opacity: 0, scale: 0.9 }}
              whileInView={{ opacity: 1, scale: 1 }}
              viewport={{ once: true }}
              transition={{ delay: i * 0.1 }}
              className="group cursor-pointer"
            >
              <div className="relative aspect-[9/19] rounded-[32px] overflow-hidden border-[6px] border-text bg-text shadow-2xl">
                <img 
                  src={item.src} 
                  alt={item.title} 
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                />
                <div className="absolute inset-x-0 bottom-0 p-4 bg-gradient-to-t from-black/80 to-transparent">
                  <span className="text-white text-[10px] uppercase font-bold tracking-widest">{item.title}</span>
                </div>
              </div>
            </motion.div>
          ))}
        </div>
      </div>
    </section>
  );
};

export default AppShowcase;
