import { render, screen, waitFor } from '@testing-library/react'
import { describe, it, expect, vi, beforeEach } from 'vitest'
import App from '../App'

const planesMock = [
  { id: 1, nombre: 'Básico',  descripcion: 'Acceso estándar', precio: 29990 },
  { id: 2, nombre: 'Premium', descripcion: 'Acceso completo', precio: 59990 },
]

beforeEach(() => {
  vi.spyOn(globalThis, 'fetch').mockResolvedValue({
    ok: true,
    json: async () => planesMock,
  })
})

describe('App — lista de planes', () => {

  it('muestra el mensaje de carga al inicio', () => {
    render(<App />)
    expect(screen.getByText('CARGANDO ESPERE SENTAITO...')).toBeInTheDocument()
  })

  it('muestra los planes recibidos desde la API', async () => {
    render(<App />)

    await waitFor(() => {
      expect(screen.getByText('Básico')).toBeInTheDocument()
      expect(screen.getByText('Premium')).toBeInTheDocument()
    })
  })

  it('muestra descripcion y precio de cada plan', async () => {
    render(<App />)

    await waitFor(() => {
      expect(screen.getByText('Acceso estándar')).toBeInTheDocument()
      expect(screen.getByText('29990')).toBeInTheDocument()
    })
  })

})