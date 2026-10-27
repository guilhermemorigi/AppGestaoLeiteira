package com.gestao.leiteira.model;

import com.fasterxml.jackson.annotation.JsonIncludeProperties;
import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;
import java.time.LocalDateTime;

@Entity
@Table(name = "health_records")
public class HealthRecord {

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
    private String tipo; // Doença, Tratamento, Exame, Cirurgia, Vermífugo

    @Column(nullable = false)
    private String descricao;

    private String medicamento;

    private String veterinario;

    @Column(nullable = false)
    private LocalDateTime data;

    private LocalDateTime dataFim;

    // Dinheiro: NUMERIC(12,2) no banco (exato), Double no Java
    @JdbcTypeCode(SqlTypes.NUMERIC)
    @Column(nullable = false, precision = 12, scale = 2)
    private Double custo = 0.0;

    private String status = "Em andamento"; // Em andamento, Concluído

    private String observacao;

    /** Despesa gerada automaticamente a partir do custo do registro. */
    @OneToOne(cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "expense_id")
    @JsonIgnore
    private Expense despesa;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Animal getAnimal() { return animal; }
    public void setAnimal(Animal animal) { this.animal = animal; }

    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }

    public String getDescricao() { return descricao; }
    public void setDescricao(String descricao) { this.descricao = descricao; }

    public String getMedicamento() { return medicamento; }
    public void setMedicamento(String medicamento) { this.medicamento = medicamento; }

    public String getVeterinario() { return veterinario; }
    public void setVeterinario(String veterinario) { this.veterinario = veterinario; }

    public LocalDateTime getData() { return data; }
    public void setData(LocalDateTime data) { this.data = data; }

    public LocalDateTime getDataFim() { return dataFim; }
    public void setDataFim(LocalDateTime dataFim) { this.dataFim = dataFim; }

    public Double getCusto() { return custo; }
    public void setCusto(Double custo) { this.custo = custo; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getObservacao() { return observacao; }
    public void setObservacao(String observacao) { this.observacao = observacao; }

    public Expense getDespesa() { return despesa; }
    public void setDespesa(Expense despesa) { this.despesa = despesa; }
}
