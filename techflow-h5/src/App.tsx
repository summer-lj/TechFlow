import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';

import { getDefaultBusinessSlug } from './lib/runtime';
import { RegisterPage } from './pages/RegisterPage';

export default function App() {
  const defaultBusinessSlug = getDefaultBusinessSlug();

  return (
    <BrowserRouter basename="/h5">
      <Routes>
        <Route path="/" element={<Navigate to={`/register/${defaultBusinessSlug}`} replace />} />
        <Route
          path="/register"
          element={<Navigate to={`/register/${defaultBusinessSlug}`} replace />}
        />
        <Route path="/register/:businessSlug" element={<RegisterPage />} />
        <Route path="*" element={<Navigate to={`/register/${defaultBusinessSlug}`} replace />} />
      </Routes>
    </BrowserRouter>
  );
}
