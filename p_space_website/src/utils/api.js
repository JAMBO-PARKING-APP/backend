import axios from 'axios';
import { getToken } from './auth';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000/api';

const getHeaders = () => {
    return {
        headers: {
            Authorization: `Bearer ${getToken()}`
        }
    };
};

export const fetchOwnerZones = async () => {
    const res = await axios.get(`${API_URL}/parking/owner/zones/`, getHeaders());
    return res.data;
};

export const updateOwnerZone = async (id, data) => {
    const res = await axios.patch(`${API_URL}/parking/owner/zones/${id}/`, data, getHeaders());
    return res.data;
};

export const submitZoneApplication = async (data) => {
    // data can be FormData if documents are included
    let headers = getHeaders().headers;
    if (data instanceof FormData) {
        headers['Content-Type'] = 'multipart/form-data';
    }
    const res = await axios.post(`${API_URL}/parking/applications/`, data, { headers });
    return res.data;
};
