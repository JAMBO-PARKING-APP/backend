import axios from 'axios';

// Update with your actual API URL
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';

export const loginWithPhone = async (phoneNumber) => {
    return axios.post(`${API_URL}/accounts/login/`, { phone_number: phoneNumber });
};

export const verifyOTP = async (phoneNumber, otp) => {
    const response = await axios.post(`${API_URL}/accounts/verify-otp/`, { 
        phone_number: phoneNumber, 
        otp: otp 
    });
    if (response.data.access) {
        localStorage.setItem('access_token', response.data.access);
        localStorage.setItem('user', JSON.stringify(response.data.user));
    }
    return response.data;
};

export const logout = () => {
    localStorage.removeItem('access_token');
    localStorage.removeItem('user');
};

export const getToken = () => localStorage.getItem('access_token');

export const getUser = () => {
    const userStr = localStorage.getItem('user');
    return userStr ? JSON.parse(userStr) : null;
};

export const isAuthenticated = () => !!getToken();

// Setup axios interceptor
axios.interceptors.request.use(config => {
    const token = getToken();
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
}, error => Promise.reject(error));
