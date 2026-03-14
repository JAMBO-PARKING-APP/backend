import React from 'react';
import Hero from '../components/Hero';
import Features from '../components/Features';
import LiveDashboard from '../components/LiveDashboard';
import AddParkingForm from '../components/AddParkingForm';

const HomePage = () => {
  return (
    <main>
      <Hero />
      <Features />
      <LiveDashboard />
      <AddParkingForm />
    </main>
  );
};

export default HomePage;
