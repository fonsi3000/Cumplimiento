<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up()
    {
        Schema::create('debida_diligencias', function (Blueprint $table) {
            $table->id();
            $table->string('debida_diligencia')->nullable();
            $table->date('fecha_ingreso_correo')->nullable();
            $table->time('hora_ingreso_correo')->nullable();
            $table->enum('empresa_solicitante', [
                'ESPUMAS MEDELLÍN S.A',
                'ESPUMADOS DEL LITORAL S.A',
                'STN CARGA & LOGÍSTICA S.A.S'
            ])->nullable();
            $table->enum('responsable', [
                'Edy Arenas Montoya',
                'Sofia Velez',
                'Catalina Hernández'
            ])->nullable();
            $table->date('fecha_respuesta')->nullable();
            $table->enum('estado', ['Terminado', 'Pendiente'])->default('Pendiente');
            $table->enum('nivel_riesgo', ['Alto', 'Medio', 'Bajo'])->default('Bajo');
            $table->boolean('coincidencia_listas')->default(false);
            $table->boolean('coincidencia_noticia')->default(false);
            $table->boolean('correo_enviado_oc')->default(false);
            $table->enum('tipo_vinculacion', ['Nuevo', 'Actualizado'])->nullable();
            $table->enum('contraparte', ['Cliente', 'Proveedor', 'Colaborador'])->nullable();
            $table->enum('tipo_persona', ['Natural', 'Jurídica', 'Internacional'])->nullable();
            $table->enum('documentacion', ['Completa', 'Incompleta', 'Pendiente'])->default('Pendiente');
            $table->enum('area_solicitante', ['Cartera', 'Compras', 'Gestion Humana'])->nullable();
            $table->text('observaciones_documentacion')->nullable();
            $table->date('fecha_recepcion_documentos')->nullable();
            $table->time('hora_recepcion')->nullable();
            // Nuevos campos agregados
            $table->boolean('consulta')->nullable();
            $table->integer('beneficiario_final')->nullable();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down()
    {
        Schema::dropIfExists('debida_diligencias');
    }
};
