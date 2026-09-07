package com.gestao.leiteira.model;

import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "stock_items")
public class StockItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nome;

    private String categoria; // Ração, Medicamento, Vacina, Higiene, Equipamento, Outros

    @Column(nullable = false)
    private Double quantidade = 0.0;

    private String unidade; // kg, L, un, saco, dose

    private Double quantidadeMinima = 0.0;

    private Double precoUnitario = 0.0;

    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd'T'HH:mm:ss.SSS")
    private LocalDateTime validade;

    private String observacao;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public String getCategoria() { return categoria; }
    public void setCategoria(String categoria) { this.categoria = categoria; }

    public Double getQuantidade() { return quantidade; }
    public void setQuantidade(Double quantidade) { this.quantidade = quantidade; }

    public String getUnidade() { return unidade; }
    public void setUnidade(String unidade) { this.unidade = unidade; }

    public Double getQuantidadeMinima() { return quantidadeMinima; }
    public void setQuantidadeMinima(Double quantidadeMinima) { this.quantidadeMinima = quantidadeMinima; }

    public Double getPrecoUnitario() { return precoUnitario; }
    public void setPrecoUnitario(Double precoUnitario) { this.precoUnitario = precoUnitario; }

    public LocalDateTime getValidade() { return validade; }
    public void setValidade(LocalDateTime validade) { this.validade = validade; }

    public String getObservacao() { return observacao; }
    public void setObservacao(String observacao) { this.observacao = observacao; }
}
