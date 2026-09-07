package com.gestao.leiteira.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "reproductions")
public class Reproduction {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne
    @JoinColumn(name = "animal_id", nullable = false)
    private Animal animal;

    @Column(nullable = false)
    private String tipo; // Cio, Cobertura, Inseminação, Diagnóstico Gestação, Parto

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS")
    @Column(nullable = false)
    private LocalDateTime data;

    private String touro; // identificação do touro ou sêmen

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS")
    private LocalDateTime previsaoParto;

    private String status = "Pendente"; // Pendente, Confirmada, Prenhe, Vazia, Parida

    private String observacao;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Animal getAnimal() { return animal; }
    public void setAnimal(Animal animal) { this.animal = animal; }

    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }

    public LocalDateTime getData() { return data; }
    public void setData(LocalDateTime data) { this.data = data; }

    public String getTouro() { return touro; }
    public void setTouro(String touro) { this.touro = touro; }

    public LocalDateTime getPrevisaoParto() { return previsaoParto; }
    public void setPrevisaoParto(LocalDateTime previsaoParto) { this.previsaoParto = previsaoParto; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getObservacao() { return observacao; }
    public void setObservacao(String observacao) { this.observacao = observacao; }
}
