<?php

namespace App\Filament\Resources\DebidaDiligenciaResource\Pages;

use App\Filament\Resources\DebidaDiligenciaResource;
use Filament\Actions;
use Filament\Resources\Pages\ListRecords;

class ListDebidaDiligencias extends ListRecords
{
    protected static string $resource = DebidaDiligenciaResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Actions\CreateAction::make(),
        ];
    }
}
