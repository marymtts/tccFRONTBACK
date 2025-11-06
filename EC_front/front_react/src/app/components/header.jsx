"use client";
import './header.css';
import React from 'react';
import Dock from './Dock';

function Header() { 

  const items = [
    { label: 'Home', onClick: () => alert('Home!') },
    { label: 'Archive', onClick: () => alert('Archive!') },
    { label: 'Profile', onClick: () => alert('Profile!') },
    { label: 'Settings', onClick: () => alert('Settings!') },
  ];

  return (
    <header className='header'>
      <Dock 
    items={items}
    panelHeight={68}
    baseItemSize={50}
    magnification={70}
  />
    </header>

  )
} export default Header;