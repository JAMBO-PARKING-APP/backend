import React from 'react';
import { Link } from 'react-router-dom';
import { ParkingCircle, Github, Twitter, Linkedin, Mail } from 'lucide-react';

const Footer = () => {
  return (
    <footer className="bg-text text-white py-20">
      <div className="container">
        <div className="grid md:grid-cols-4 gap-12 mb-16">
          <div className="col-span-1 md:col-span-1">
            <div className="flex items-center gap-2 mb-6">
              <div className="premium-gradient p-2 rounded-xl">
                <ParkingCircle color="white" size={24} />
              </div>
              <span className="text-xl font-bold tracking-tight">SPACE PARK</span>
            </div>
            <p className="text-gray-400 text-sm leading-relaxed mb-6">
              The next generation of urban infrastructure management. Smart cities start with smart parking.
            </p>
            <div className="flex gap-4">
              {[Twitter, Github, Linkedin].map((Icon, i) => (
                <a key={i} href="#" className="w-10 h-10 rounded-full bg-white/5 flex items-center justify-center hover:bg-primary transition-colors">
                  <Icon size={18} />
                </a>
              ))}
            </div>
          </div>

          <div>
            <h4 className="font-bold mb-6">Product</h4>
            <ul className="space-y-4 text-gray-400 text-sm">
              <li><a href="#" className="hover:text-white transition-colors no-underline">User Experience</a></li>
              <li><a href="#" className="hover:text-white transition-colors no-underline">Enforcement Tools</a></li>
              <li><a href="#" className="hover:text-white transition-colors no-underline">Admin Console</a></li>
              <li><a href="#" className="hover:text-white transition-colors no-underline">API Documentation</a></li>
            </ul>
          </div>

          <div>
            <h4 className="font-bold mb-6">Company</h4>
            <ul className="space-y-4 text-gray-400 text-sm list-none p-0">
              <li><Link to="/terms" className="hover:text-white transition-colors no-underline text-gray-400">Terms & Conditions</Link></li>
              <li><Link to="/privacy" className="hover:text-white transition-colors no-underline text-gray-400">Privacy Policy</Link></li>
              <li><a href="#" className="hover:text-white transition-colors no-underline">Success Stories</a></li>
              <li><a href="#" className="hover:text-white transition-colors no-underline">Contact Support</a></li>
            </ul>
          </div>

          <div>
            <h4 className="font-bold mb-6">Stay Updated</h4>
            <p className="text-gray-400 text-sm mb-4">Get the latest on smart city innovations.</p>
            <div className="relative">
              <input 
                type="email" 
                placeholder="email@example.com" 
                className="w-full bg-white/5 border border-white/10 p-3 rounded-xl focus:outline-none focus:ring-1 focus:ring-primary text-sm text-white"
              />
              <button className="absolute right-2 top-1/2 -translate-y-1/2 p-1 text-primary bg-transparent border-none cursor-pointer">
                <Mail size={18} />
              </button>
            </div>
          </div>
        </div>

        <div className="pt-8 border-t border-white/10 flex flex-col md:flex-row justify-between items-center gap-4 text-xs text-gray-500 font-medium uppercase tracking-widest">
          <p>© 2026 SPACE PARK SOLUTIONS. ALL RIGHTS RESERVED.</p>
          <div className="flex gap-8">
            <Link to="/privacy" className="hover:text-white transition-colors no-underline text-gray-500">Privacy Policy</Link>
            <Link to="/terms" className="hover:text-white transition-colors no-underline text-gray-500">Terms of Service</Link>
            <a href="#" className="hover:text-white transition-colors no-underline">Imprint</a>
          </div>
        </div>
      </div>
    </footer>
  );
};

export default Footer;
