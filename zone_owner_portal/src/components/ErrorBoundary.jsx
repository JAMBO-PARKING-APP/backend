import { Component } from 'react';

class ErrorBoundary extends Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null };
  }

  static getDerivedStateFromError(error) {
    return { hasError: true, error };
  }

  componentDidCatch(error, errorInfo) {
    console.error('Error caught by boundary:', error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'center',
          minHeight: '100vh',
          padding: '20px',
          background: 'var(--bg-base)',
          color: 'var(--text-primary)'
        }}>
          <h2 style={{ marginBottom: '16px' }}>Something went wrong</h2>
          <p style={{ marginBottom: '20px', textAlign: 'center' }}>
            We encountered an error while loading this page. Please refresh to try again.
          </p>
          <button
            onClick={() => window.location.reload()}
            style={{
              padding: '12px 24px',
              background: 'var(--accent)',
              color: 'white',
              border: 'none',
              borderRadius: 'var(--radius-md)',
              cursor: 'pointer',
              fontSize: '14px',
              fontWeight: '500'
            }}
          >
            Refresh Page
          </button>
          {process.env.NODE_ENV === 'development' && (
            <details style={{ marginTop: '20px', maxWidth: '600px' }}>
              <summary style={{ cursor: 'pointer', marginBottom: '10px' }}>Error Details (Development)</summary>
              <pre style={{
                background: 'var(--bg-card)',
                padding: '10px',
                borderRadius: 'var(--radius-sm)',
                fontSize: '12px',
                overflow: 'auto',
                color: 'var(--danger)'
              }}>
                {this.state.error?.toString()}
              </pre>
            </details>
          )}
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;