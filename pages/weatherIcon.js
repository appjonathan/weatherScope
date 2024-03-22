import React from 'react';
import { WiDaySunny, WiRain, WiSnow, WiCloud, WiFog, WiThunderstorm, WiShowers, WiHail, WiSleet, WiDust, WiSmoke, WiStrongWind, WiTornado, WiHurricane, WiSnowflakeCold } from 'react-icons/wi';

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
    case 'Hail':
      return <WiHail />;
    case 'Sleet':
      return <WiSleet />;
    case 'Dust':
      return <WiDust />;
    case 'Fog':
      return <WiFog />;
    case 'Smoke':
      return <WiSmoke />;
    case 'Strong Wind':
      return <WiStrongWind />;
    case 'Tornado':
      return <WiTornado />;
    case 'Hurricane':
      return <WiHurricane />;
    case 'Cold':
      return <WiSnowflakeCold />;
    default:
      return null;
  }
}

const WeatherIconPage = () => {
  // render logic for the page
  return <div>Weather Icon Page</div>;
}

export default WeatherIconPage;