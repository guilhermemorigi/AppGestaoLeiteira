package com.gestao.leiteira.model;

import com.fasterxml.jackson.annotation.JsonIncludeProperties;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "production")
public class Production {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "animal_id", nullable = false)
    // Nas listagens basta identificar o animal: evita repetir o cadastro
    // completo em cada registro (respostas bem menores)
    @JsonIncludeProperties({"id", "nome"})
    private Animal animal;

    @Column(nullable = false)
    private LocalDateTime data;

    @Column(nullable = false)
    private Double quantidade;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Animal getAnimal() { return animal; }
    public void setAnimal(Animal animal) { this.animal = animal; }

    public LocalDateTime getData() { return data; }
    public void setData(LocalDateTime data) { this.data = data; }

    public Double getQuantidade() { return quantidade; }
    public void setQuantidade(Double quantidade) { this.quantidade = quantidade; }
}
