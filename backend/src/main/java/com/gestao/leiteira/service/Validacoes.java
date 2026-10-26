package com.gestao.leiteira.service;

import com.gestao.leiteira.exception.ApiException;

/**
 * Validações simples de entrada compartilhadas pelos services.
 */
final class Validacoes {

    private Validacoes() {}

    /** Garante texto não vazio e devolve o valor sem espaços nas pontas. */
    static String texto(String valor, String campo) {
        if (valor == null || valor.isBlank()) {
            throw ApiException.badRequest("O campo '" + campo + "' é obrigatório.");
        }
        return valor.trim();
    }

    static <T> T obrigatorio(T valor, String campo) {
        if (valor == null) {
            throw ApiException.badRequest("O campo '" + campo + "' é obrigatório.");
        }
        return valor;
    }

    static void positivo(Double valor, String campo) {
        if (valor == null || valor <= 0) {
            throw ApiException.badRequest("O campo '" + campo + "' deve ser maior que zero.");
        }
    }

    static void naoNegativo(Double valor, String campo) {
        if (valor != null && valor < 0) {
            throw ApiException.badRequest("O campo '" + campo + "' não pode ser negativo.");
        }
    }

    /** Corta o texto no tamanho máximo da coluna (varchar 255 por padrão). */
    static String limitar(String valor, int max) {
        return valor == null || valor.length() <= max ? valor : valor.substring(0, max);
    }
}
