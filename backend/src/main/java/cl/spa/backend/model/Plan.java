
package cl.spa.backend.model;

import jakarta.persistence.*;

/**
 *
 * @author Duoc
 */
@Entity
@Table(name="plan")
public class Plan {
    
    @Id
    @GeneratedValue(strategy=GenerationType.IDENTITY)
    private Long id;
    private String nombre;
    private String descripcion;
    private Double precio;

    public Plan() {
    }

    public Plan(String nombre, String descripcion, Double precio) {
        this.nombre = nombre;
        this.descripcion = descripcion;
        this.precio = precio;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getDescripcion() {
        return descripcion;
    }

    public void setDescripcion(String descripcion) {
        this.descripcion = descripcion;
    }

    public Double getPrecio() {
        return precio;
    }

    public void setPrecio(Double precio) {
        this.precio = precio;
    }
    
    
}
