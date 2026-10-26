package com.gestao.leiteira.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "animals")
public class Animal {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String nome;

    private Integer idade;
    private String raca;

    private String numeroBrinco; // identificação/brinco
    private String sexo; // Fêmea, Macho
    private Double peso; // kg

    private LocalDateTime dataNascimento;

    private String status = "Ativo"; // Ativo, Vendido, Morto, Seco, Lactação

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getNome() { return nome; }
    public void setNome(String nome) { this.nome = nome; }

    public Integer getIdade() { return idade; }
    public void setIdade(Integer idade) { this.idade = idade; }

    public String getRaca() { return raca; }
    public void setRaca(String raca) { this.raca = raca; }

    public String getNumeroBrinco() { return numeroBrinco; }
    public void setNumeroBrinco(String numeroBrinco) { this.numeroBrinco = numeroBrinco; }

    public String getSexo() { return sexo; }
    public void setSexo(String sexo) { this.sexo = sexo; }

    public Double getPeso() { return peso; }
    public void setPeso(Double peso) { this.peso = peso; }

    public LocalDateTime getDataNascimento() { return dataNascimento; }
    public void setDataNascimento(LocalDateTime dataNascimento) { this.dataNascimento = dataNascimento; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
