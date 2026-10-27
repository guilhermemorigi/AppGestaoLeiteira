package com.gestao.leiteira.model;

import com.fasterxml.jackson.annotation.JsonIncludeProperties;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "vaccines")
public class Vaccine {

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
    private String nome; // Aftosa, Brucelose, Raiva, Clostridiose, etc.

    @Column(nullable = false)
    private LocalDateTime dataAplicacao;

    private LocalDateTime proximaDose;

    private String lote;

    private String veterinario;

    private String observacao;

    /** Lembrete da próxima dose, criado automaticamente na Agenda. */
    @OneToOne(cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "reminder_id")
    @JsonIgnore
    private Reminder lembrete;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Animal getAnimal() { return animal; }
    public void setAnimal(Animal animal) { this.animal = animal; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public LocalDateTime getDataAplicacao() { return dataAplicacao; }
    public void setDataAplicacao(LocalDateTime dataAplicacao) { this.dataAplicacao = dataAplicacao; }

    public LocalDateTime getProximaDose() { return proximaDose; }
    public void setProximaDose(LocalDateTime proximaDose) { this.proximaDose = proximaDose; }

    public String getLote() { return lote; }
    public void setLote(String lote) { this.lote = lote; }

    public String getVeterinario() { return veterinario; }
    public void setVeterinario(String veterinario) { this.veterinario = veterinario; }

    public String getObservacao() { return observacao; }
    public void setObservacao(String observacao) { this.observacao = observacao; }

    public Reminder getLembrete() { return lembrete; }
    public void setLembrete(Reminder lembrete) { this.lembrete = lembrete; }
}
