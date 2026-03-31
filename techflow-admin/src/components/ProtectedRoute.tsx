import { Navigate, Outlet, useLocation } from 'react-router-dom';

import { useAuth } from '../auth';

export function ProtectedRoute() {
  const auth = useAuth();
  const location = useLocation();

  if (auth.status === 'loading') {
    return (
      <div className="loading-screen">
        <div className="loading-orb" />
        <p>正在校验后台会话...</p>
      </div>
    );
  }

  if (auth.status !== 'authenticated') {
    return <Navigate to="/login" replace state={{ from: location.pathname }} />;
  }

  return <Outlet />;
}
