import React from 'react';
import Hero from '../components/Hero';
import Features from '../components/Features';
import AppShowcase from '../components/AppShowcase';
import LiveDashboard from '../components/LiveDashboard';
import AddParkingForm from '../components/AddParkingForm';

const HomePage = () => {
  return (
    <main>
      <Hero />
      <AppShowcase />
      <Features />
      <LiveDashboard />
      <AddParkingForm />
    </main>
  );
};

export default HomePage;
