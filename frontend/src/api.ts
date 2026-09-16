import type { AuthUser, Task, TaskPayload, TaskStatus } from './types'

const API_BASE = import.meta.env.VITE_API_URL ?? ''

class ApiError extends Error {
  status: number

  constructor(message: string, status: number) {
    super(message)
    this.status = status
  }
}

async function request<T>(
  path: string,
  options: RequestInit = {},
  token?: string | null,
): Promise<T> {
  const headers = new Headers(options.headers)
  headers.set('Content-Type', 'application/json')
  if (token) {
    headers.set('Authorization', `Bearer ${token}`)
  }

  const response = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers,
  })

  if (response.status === 204) {
    return undefined as T
  }

  const data = await response.json().catch(() => ({}))
  if (!response.ok) {
    throw new ApiError(data.message || 'Une erreur est survenue', response.status)
  }
  return data as T
}

export const api = {
  register(payload: { email: string; password: string; fullName: string }) {
    return request<AuthUser>('/api/auth/register', {
      method: 'POST',
      body: JSON.stringify(payload),
    })
  },
  login(payload: { email: string; password: string }) {
    return request<AuthUser>('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify(payload),
    })
  },
  listTasks(token: string, status?: TaskStatus | 'ALL', search?: string) {
    const params = new URLSearchParams()
    if (status && status !== 'ALL') params.set('status', status)
    if (search?.trim()) params.set('search', search.trim())
    const query = params.toString()
    return request<Task[]>(`/api/tasks${query ? `?${query}` : ''}`, {}, token)
  },
  createTask(token: string, payload: TaskPayload) {
    return request<Task>('/api/tasks', {
      method: 'POST',
      body: JSON.stringify(payload),
    }, token)
  },
  updateTask(token: string, id: number, payload: TaskPayload) {
    return request<Task>(`/api/tasks/${id}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    }, token)
  },
  deleteTask(token: string, id: number) {
    return request<void>(`/api/tasks/${id}`, { method: 'DELETE' }, token)
  },
}

export { ApiError }
