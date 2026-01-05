import React, { useState, useEffect } from 'react';
import './App.css';

function App() {
  const [message, setMessage] = useState('Loading...');
  const [error, setError] = useState(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setIsLoading(true);
    setError(null);
    
    try {
      // Try to call the API endpoint
      // In production, this would be /api/hello
      const apiUrl = process.env.REACT_APP_FUNCTION_APP_URL 
        ? `${process.env.REACT_APP_FUNCTION_APP_URL}/api/hello`
        : '/api/hello';
      
      const response = await fetch(apiUrl);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const data = await response.json();
      setMessage(data.message || 'Hello from Azure!');
    } catch (err) {
      console.error('Error fetching data:', err);
      setError('Failed to connect to API. Using default message.');
      setMessage('Hello from Azure Static Web App! (API not connected yet)');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>🚀 Full Stack Demo</h1>
        <div className="status-card">
          {isLoading ? (
            <div className="loading">
              <div className="spinner"></div>
              <p>Connecting to backend...</p>
            </div>
          ) : (
            <>
              <p className="message">{message}</p>
              {error && <p className="error">{error}</p>}
            </>
          )}
        </div>
        
        <div className="info-grid">
          <div className="info-card">
            <h2>Frontend</h2>
            <p>React App</p>
            <p>Azure Static Web Apps</p>
          </div>
          
          <div className="info-card">
            <h2>Backend</h2>
            <p>Azure Functions</p>
            <p>Node.js Runtime</p>
          </div>
          
          <div className="info-card">
            <h2>Infrastructure</h2>
            <p>Terraform</p>
            <p>Infrastructure as Code</p>
          </div>
          
          <div className="info-card">
            <h2>CI/CD</h2>
            <p>GitHub Actions</p>
            <p>OIDC Authentication</p>
          </div>
        </div>

        <button className="refresh-button" onClick={fetchData}>
          Refresh Connection
        </button>

        <div className="links">
          <a
            href="https://github.com/htekdev/full-stack-demo"
            target="_blank"
            rel="noopener noreferrer"
          >
            View Source Code
          </a>
          <span>|</span>
          <a
            href="https://learn.microsoft.com/azure/static-web-apps"
            target="_blank"
            rel="noopener noreferrer"
          >
            Azure Static Web Apps Docs
          </a>
        </div>
      </header>
    </div>
  );
}

export default App;
