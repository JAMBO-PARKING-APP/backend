import React, { useState } from 'react';
import { motion } from 'framer-motion';
import { Building2, MapPin, Tablet, Phone, Send, CheckCircle2, ShieldAlert, RefreshCw } from 'lucide-react';

const AddParkingForm = () => {
  const [submitted, setSubmitted] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleSubmit = (e) => {
    e.preventDefault();
    setLoading(true);
    // Simulate API call
    setTimeout(() => {
      setLoading(false);
      setSubmitted(true);
    }, 1500);
  };

  if (submitted) {
    return (
      <section id="partners" className="section-padding bg-primary text-white text-center">
        <div className="container">
          <motion.div 
            initial={{ scale: 0.8, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="max-w-md mx-auto"
          >
            <CheckCircle2 size={80} className="mx-auto mb-6 text-accent" />
            <h2 className="text-4xl font-extrabold mb-4">Inquiry Received!</h2>
            <p className="text-primary-light text-lg mb-8">
              Thank you for choosing Space Park. Our municipal partner team will contact you within 24 hours to begin the digital transition of your space.
            </p>
            <button 
              onClick={() => setSubmitted(false)}
              className="btn bg-white text-primary font-bold"
            >
              SUBMIT ANOTHER SPACE
            </button>
          </motion.div>
        </div>
      </section>
    );
  }

  return (
    <section id="partners" className="section-padding bg-white overflow-hidden relative">
      <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-transparent via-gray-100 to-transparent" />
      
      <div className="container grid lg:grid-cols-2 gap-16 items-center">
        <div>
          <h2 className="text-4xl md:text-5xl font-extrabold text-text mb-6">
            Monetize your <br />
            <span className="text-primary">Parking Space.</span>
          </h2>
          <p className="text-lg text-text-muted mb-10">
            Join the Space Park network and turn your under-utilized property into a managed digital asset. We provide the sensors, the app, and the revenue collection infrastructure.
          </p>

          <div className="space-y-6">
            {[
              { icon: Building2, title: "Property Owners", text: "Fill vacancies and maximize ROI on your urban land." },
              { icon: Tablet, title: "Municipalities", text: "Digitalize city parking with zero upfront infrastructure cost." },
              { icon: ShieldAlert, title: "Private Operators", text: "Professionalize your enforcement with our ruggedized officer tools." }
            ].map((item, i) => (
              <div key={i} className="flex gap-4">
                <div className="w-12 h-12 shrink-0 rounded-xl bg-primary/5 flex items-center justify-center text-primary">
                  <item.icon size={24} />
                </div>
                <div>
                  <h4 className="font-bold text-text">{item.title}</h4>
                  <p className="text-sm text-text-muted">{item.text}</p>
                </div>
              </div>
            ))}
          </div>
        </div>

        <motion.div 
          initial={{ x: 50, opacity: 0 }}
          whileInView={{ x: 0, opacity: 1 }}
          viewport={{ once: true }}
          className="glass-morphism bg-surface p-10 rounded-[40px] border border-gray-100"
        >
          <form onSubmit={handleSubmit} className="space-y-6 text-left">
            <h3 className="text-2xl font-bold mb-8">Partner Inquiry</h3>
            
            <div className="grid md:grid-cols-2 gap-6">
              <div className="flex flex-col gap-2">
                <label className="text-xs font-bold text-text-muted uppercase text-left">Full Name</label>
                <input required type="text" placeholder="John Doe" className="w-full p-4 rounded-2xl bg-white border border-gray-100 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all" />
              </div>
              <div className="flex flex-col gap-2">
                <label className="text-xs font-bold text-text-muted uppercase text-left">Phone Number</label>
                <div className="relative">
                  <Phone size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-text-muted" />
                  <input required type="tel" placeholder="+256 ..." className="w-full p-4 pl-12 rounded-2xl bg-white border border-gray-100 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all" />
                </div>
              </div>
            </div>

            <div className="flex flex-col gap-2">
              <label className="text-xs font-bold text-text-muted uppercase text-left">Parking Location</label>
              <div className="relative">
                <MapPin size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-text-muted" />
                <input required type="text" placeholder="e.g. Kampala Road, Block 4" className="w-full p-4 pl-12 rounded-2xl bg-white border border-gray-100 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all" />
              </div>
            </div>

            <div className="flex flex-col gap-2">
              <label className="text-xs font-bold text-text-muted uppercase text-left">Estimated Capacity</label>
              <select className="w-full p-4 rounded-2xl bg-white border border-gray-100 focus:outline-none focus:ring-2 focus:ring-primary/20 transition-all">
                <option>1-10 Slots</option>
                <option>10-50 Slots</option>
                <option>50-100 Slots</option>
                <option>100+ Slots</option>
              </select>
            </div>

            <button 
              type="submit" 
              disabled={loading}
              className="btn btn-primary w-full py-5 flex items-center justify-center gap-3 text-lg"
            >
              {loading ? <RefreshCw className="animate-spin" /> : <Send size={20} />}
              {loading ? 'PROCESSING...' : 'SUBMIT PARTNERSHIP'}
            </button>
            <p className="text-[10px] text-center text-text-muted uppercase tracking-widest font-bold">
              Secure Submission • Terms of Service Apply
            </p>
          </form>
        </motion.div>
      </div>
    </section>
  );
};

export default AddParkingForm;
