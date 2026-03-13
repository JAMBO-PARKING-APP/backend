import React, { useState, useEffect } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Menu, X, ParkingCircle } from 'lucide-react';

const Header = () => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const location = useLocation();
  const isHome = location.pathname === '/';

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  const navLinks = [
    { name: 'Features', path: isHome ? '#features' : '/#features' },
    { name: 'App Gallery', path: isHome ? '#marketplace' : '/#marketplace' },
    { name: 'Real-time Map', path: isHome ? '#real-time-map' : '/#real-time-map' },
    { name: 'Partners', path: isHome ? '#partners' : '/#partners' },
  ];

  return (
    <header 
      className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
        isScrolled ? 'glass-morphism py-3' : 'bg-transparent py-5'
      }`}
      style={{
        backdropFilter: isScrolled ? 'blur(12px)' : 'none',
        backgroundColor: isScrolled ? 'rgba(255, 255, 255, 0.8)' : 'transparent'
      }}
    >
      <div className="container flex justify-between items-center">
        <Link to="/" className="flex items-center gap-2 cursor-pointer no-underline">
          <div className="premium-gradient p-2 rounded-xl">
            <ParkingCircle color="white" size={28} />
          </div>
          <span className="text-xl font-bold tracking-tight text-primary">SPACE PARK</span>
        </Link>

        {/* Desktop Nav */}
        <nav className="hidden md:flex items-center gap-8">
          {navLinks.map((link) => (
            link.path.startsWith('#') ? (
              <a 
                key={link.name} 
                href={link.path}
                className="text-sm font-semibold hover:text-primary transition-colors text-text no-underline"
              >
                {link.name}
              </a>
            ) : (
              <Link
                key={link.name}
                to={link.path}
                className="text-sm font-semibold hover:text-primary transition-colors text-text no-underline"
              >
                {link.name}
              </Link>
            )
          ))}
          <button className="btn btn-primary">GO PREMIUM</button>
        </nav>

        {/* Mobile Toggle */}
        <button 
          className="md:hidden p-2"
          onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
        >
          {isMobileMenuOpen ? <X /> : <Menu />}
        </button>
      </div>

      {/* Mobile Menu */}
      {isMobileMenuOpen && (
        <div className="md:hidden glass-morphism absolute top-full left-0 right-0 p-6 animate-fade-in">
          <div className="flex flex-col gap-4">
            {navLinks.map((link) => (
              <Link
                key={link.name}
                to={link.path}
                className="text-lg font-medium text-text no-underline"
                onClick={() => setIsMobileMenuOpen(false)}
              >
                {link.name}
              </Link>
            ))}
            <button className="btn btn-primary w-full mt-4">GO PREMIUM</button>
          </div>
        </div>
      )}
    </header>
  );
};

export default Header;
