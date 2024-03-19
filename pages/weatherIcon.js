import React from 'react';
import { WiDaySunny, WiRain, WiSnow, WiCloud, WiFog, WiThunderstorm, WiShowers } from 'react-icons/wi';

export function getWeatherIcon(weather) {
  switch (weather) {
    case 'Clear':
      return <WiDaySunny />;
    case 'Rain':
      return <WiRain />;
    case 'Snow':
      return <WiSnow />;
    case 'Clouds':
      return <WiCloud />;
    case 'Atmosphere':
      return <WiFog />;
    case 'Thunderstorm':
      return <WiThunderstorm />;
    case 'Drizzle':
      return <WiShowers />;
  }
}

export default function WeatherIcon() {
    return null;
  }