import { createContext, useContext, useState, useCallback } from 'react';
import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export const api = axios.create({ baseURL: `${BASE_URL}/api/partner` });
export const parkingApi = axios.create({ baseURL: `${BASE_URL}/api/parking` });
export const userApi = axios.create({ baseURL: `${BASE_URL}/api/user` });

// Attach JWT to every request for both APIs
const attachToken = (config) => {
  const token = localStorage.getItem('partner_access');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
};

api.interceptors.request.use(attachToken);
parkingApi.interceptors.request.use(attachToken);
userApi.interceptors.request.use(attachToken);

// Auto-logout on 401 for both APIs
const handle401 = (err) => {
  if (err.response?.status === 401) {
    localStorage.removeItem('partner_access');
    localStorage.removeItem('partner_refresh');
    localStorage.removeItem('partner_user');
    window.location.href = '/login';
  }
  return Promise.reject(err);
};

api.interceptors.response.use(res => res, handle401);
parkingApi.interceptors.response.use(res => res, handle401);
userApi.interceptors.response.use(res => res, handle401);

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    try { return JSON.parse(localStorage.getItem('partner_user')); } catch { return null; }
  });
  const [hasBankDetails, setHasBankDetails] = useState(false);

  const login = useCallback(async (email, password) => {
    const res = await api.post('/login/', { email, password });
    const { access, refresh, user: userData, has_bank_details } = res.data;
    localStorage.setItem('partner_access', access);
    localStorage.setItem('partner_refresh', refresh);
    localStorage.setItem('partner_user', JSON.stringify(userData));
    setUser(userData);
    setHasBankDetails(has_bank_details);
    return has_bank_details;
  }, []);

  const logout = useCallback(() => {
    localStorage.removeItem('partner_access');
    localStorage.removeItem('partner_refresh');
    localStorage.removeItem('partner_user');
    setUser(null);
    setHasBankDetails(false);
  }, []);

  return (
    <AuthContext.Provider value={{ user, hasBankDetails, setHasBankDetails, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
