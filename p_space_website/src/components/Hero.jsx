import React from 'react';
import { motion } from 'framer-motion';
import { Smartphone, ShieldCheck, Zap } from 'lucide-react';

const Hero = () => {
  return (
    <section className="relative overflow-hidden section-padding pt-32">
      {/* Background Orbs */}
      <div className="absolute top-0 right-0 w-[500px] h-[500px] bg-primary/5 rounded-full blur-3xl -z-10 translate-x-1/2 -translate-y-1/2" />
      <div className="absolute bottom-0 left-0 w-[300px] h-[300px] bg-accent/5 rounded-full blur-3xl -z-10 -translate-x-1/2 translate-y-1/2" />

      <div className="container grid md:grid-cols-2 gap-12 items-center">
        <motion.div 
          initial={{ opacity: 0, x: -30 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.8 }}
        >
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold mb-6">
            <Zap size={14} />
            <span>NATIONWIDE SMART PARKING</span>
          </div>
          <h1 className="text-5xl md:text-7xl font-extrabold text-text mb-6">
            Space Park, <br />
            <span className="text-primary italic">Reimagined.</span>
          </h1>
          <p className="text-xl text-text-muted mb-8 max-w-lg">
            Experience the future of urban mobility. Find, book, and pay for parking in seconds with Space Park.
          </p>
          
          <div className="flex flex-wrap gap-4">
            <button className="btn btn-primary flex items-center gap-2 px-8">
              <Smartphone size={18} />
              DOWNLOAD APP
            </button>
            <button className="btn bg-white border border-gray-200 flex items-center gap-2 hover:bg-gray-50">
              LEARN MORE
            </button>
          </div>

          <div className="mt-12 flex items-center gap-6">
            <div className="flex flex-col">
              <span className="text-2xl font-bold">50k+</span>
              <span className="text-xs text-text-muted uppercase tracking-widest">Active Users</span>
            </div>
            <div className="w-px h-10 bg-gray-200" />
            <div className="flex flex-col">
              <span className="text-2xl font-bold">200+</span>
              <span className="text-xs text-text-muted uppercase tracking-widest">Safe Zones</span>
            </div>
          </div>
        </motion.div>

        <motion.div 
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ duration: 1, delay: 0.2 }}
          className="relative"
        >
          <div className="relative z-10 p-4 bg-white/30 backdrop-blur-md rounded-[40px] border border-white/50 shadow-2xl overflow-hidden aspect-[9/16] max-w-[340px] mx-auto">
             <div className="absolute inset-0 flex flex-col items-center justify-center p-6 text-center">
               <div className="w-16 h-16 rounded-full bg-primary/20 flex items-center justify-center mb-4 backdrop-blur-md">
                 <Smartphone className="text-primary w-8 h-8" />
               </div>
               <h3 className="text-2xl font-bold text-gray-800 mb-2">Space Park</h3>
               <p className="text-sm font-medium text-gray-500">Intelligent Urban Mobility</p>
               <div className="mt-8 space-y-3 w-full">
                 <div className="h-2 w-full bg-gray-200 rounded-full overflow-hidden">
                   <motion.div 
                     initial={{ width: 0 }}
                     animate={{ width: "70%" }}
                     transition={{ duration: 1.5, ease: "easeOut" }}
                     className="h-full bg-primary"
                   />
                 </div>
                 <div className="h-2 w-4/5 bg-gray-200 rounded-full mx-auto" />
                 <div className="h-2 w-3/5 bg-gray-200 rounded-full mx-auto" />
               </div>
             </div>
          </div>
          
          {/* Floating Elements */}
          <motion.div 
            animate={{ y: [0, -10, 0] }}
            transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
            className="absolute -top-6 -right-6 glass-morphism p-4 rounded-2xl flex items-center gap-3 z-20"
          >
            <div className="w-10 h-10 rounded-lg premium-gradient flex items-center justify-center text-white">
              <ShieldCheck size={20} />
            </div>
            <div>
              <div className="text-[10px] text-text-muted font-bold">VERIFIED</div>
              <div className="text-sm font-bold">SECURE PAYMENT</div>
            </div>
          </motion.div>
        </motion.div>
      </div>
    </section>
  );
};

export default Hero;
