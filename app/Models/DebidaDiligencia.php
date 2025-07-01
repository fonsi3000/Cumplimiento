<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class DebidaDiligencia extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'debida_diligencia',
        'fecha_ingreso_correo',
        'hora_ingreso_correo',
        'empresa_solicitante',
        'responsable',
        'fecha_respuesta',
        'estado',
        'nivel_riesgo',
        'coincidencia_listas',
        'coincidencia_noticia',
        'correo_enviado_oc',
        'tipo_vinculacion',
        'contraparte',
        'tipo_persona',
        'documentacion',
        'area_solicitante',
        'observaciones_documentacion',
        'fecha_recepcion_documentos',
        'hora_recepcion',
        // Agregando los campos que faltaban
        'consulta',
        'beneficiario_final'
    ];

    protected $casts = [
        'fecha_ingreso_correo' => 'date',
        'fecha_respuesta' => 'date',
        'fecha_recepcion_documentos' => 'date',
        'hora_ingreso_correo' => 'datetime',
        'hora_recepcion' => 'datetime',
        'coincidencia_listas' => 'boolean',
        'coincidencia_noticia' => 'boolean',
        'correo_enviado_oc' => 'boolean',
        'consulta' => 'boolean',
        'beneficiario_final' => 'integer'
    ];

    // Constantes
    const EMPRESAS = [
        'ESPUMAS MEDELLÍN S.A' => 'ESPUMAS MEDELLÍN S.A',
        'ESPUMADOS DEL LITORAL S.A' => 'ESPUMADOS DEL LITORAL S.A',
        'STN CARGA & LOGÍSTICA S.A.S' => 'STN CARGA & LOGÍSTICA S.A.S'
    ];

    const RESPONSABLES = [
        'Edy Arenas Montoya' => 'Daniela Arredondo',
        'Sofia Velez' => 'Sofia Velez',
        'Catalina Hernández' => 'Catalina Hernández'
    ];

    const ESTADOS = [
        'Terminado' => 'Terminado',
        'Pendiente' => 'Pendiente'
    ];

    const NIVEL_RIESGO = [
        'Alto' => 'Alto',
        'Medio' => 'Medio',
        'Bajo' => 'Bajo'
    ];

    const TIPO_VINCULACION = [
        'Nuevo' => 'Nuevo',
        'Actualizado' => 'Actualizado'
    ];

    const CONTRAPARTE = [
        'Cliente' => 'Cliente',
        'Proveedor' => 'Proveedor',
        'Colaborador' => 'Colaborador'
    ];

    const TIPO_PERSONA = [
        'Natural' => 'Natural',
        'Jurídica' => 'Jurídica',
        'Internacional' => 'Internacional'
    ];

    const DOCUMENTACION = [
        'Completa' => 'Completa',
        'Incompleta' => 'Incompleta',
        'Pendiente' => 'Pendiente'
    ];

    const AREAS = [
        'Cartera' => 'Cartera',
        'Compras' => 'Compras',
        'Gestion Humana' => 'Gestion Humana'
    ];
}
