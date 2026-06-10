import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../shared/widgets/premium_widgets.dart';

class VistoBuenoScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String jobId;
  final bool isReadOnly;

  const VistoBuenoScreen({super.key, required this.data, required this.jobId, this.isReadOnly = false});

  @override
  State<VistoBuenoScreen> createState() => _VistoBuenoScreenState();
}

class _VistoBuenoScreenState extends State<VistoBuenoScreen> {
  bool _isApproving = false;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _aprobarReporte() async {
    setState(() => _isApproving = true);
    try {
      await FirebaseFirestore.instance.collection('trabajos').doc(widget.jobId).update({
        'estado': 'trabajo_aprobado',
        'reporteAprobado': true,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Diagnóstico aprobado! El técnico procederá con el trabajo.'), backgroundColor: Colors.green));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Future<void> _rechazarReporte() async {
    setState(() => _isApproving = true);
    try {
      await FirebaseFirestore.instance.collection('trabajos').doc(widget.jobId).update({
        'estado': 'en_sitio', // Vuelve al operario para rehacer reporte
        'reporteRechazado': true,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reporte rechazado. El técnico debe generarlo nuevamente.'), backgroundColor: Colors.orange));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isApproving = false);
    }
  }

  Widget build(BuildContext context) {
    final reporte = widget.data['reporteTecnico'] ?? {};
    final List<dynamic> listaAlquileres = reporte['alquileres'] ?? (reporte['contratoAlquiler'] != null ? [reporte['contratoAlquiler']] : []);
    final List<dynamic> listaVentas = reporte['ventas'] ?? (reporte['detalleVenta'] != null ? [reporte['detalleVenta']] : []);
    
    return Scaffold(
      appBar: const BrandedAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Resumen de Servicio',
              subtitle: 'Verifique los detalles del trabajo realizado',
            ),
            PremiumCard(
              accentColor: cAzul,
              child: Row(
                children: [
                   const Icon(Icons.description_outlined, color: cAzul, size: 32),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         const Text('RESUMEN TÉCNICO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: cAzul, letterSpacing: 1)),
                         Text('Ticket #${widget.jobId.substring(widget.jobId.length - 6).toUpperCase()}', style: const TextStyle(color: cTextoOscuro, fontSize: 16, fontWeight: FontWeight.bold)),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            _buildSection(
              'DATOS DEL PERSONAL',
              [
                _buildRow('Encargado', reporte['encargadoNombre'] ?? 'No especificado'),
                _buildRow('Identificación', reporte['encargadoCedula'] ?? 'No especificada'),
                _buildRow('Tipo Servicio', reporte['tipoServicio'] ?? 'General'),
              ],
            ),
            if ((reporte['equipos'] as List?)?.isNotEmpty == true)
              _buildSection(
                'EQUIPOS INTERVENIDOS',
                (reporte['equipos'] as List).map((e) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Equipo', e['equipoMarca'] ?? ''),
                        _buildRow('Modelo', e['modelo'] ?? ''),
                        _buildRow('Contador', e['contador'] ?? ''),
                      ],
                    ),
                  );
                }).toList(),
              ),
            if ((reporte['detallesTecnicos'] as List?)?.isNotEmpty == true)
              _buildSection(
                'DETALLES DE LA INTERVENCIÓN',
                (reporte['detallesTecnicos'] as List).map((d) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DIAGNÓSTICO:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text(d['diagnostico'] ?? '', style: const TextStyle(color: cTextoOscuro, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        const Text('SOLUCIÓN APLICADA:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text(d['solucion'] ?? '', style: const TextStyle(color: cTextoOscuro, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            if (reporte['costoEmpresa'] != null || reporte['costoTecnico'] != null)
              _buildSection(
                'LIQUIDACIÓN DE SERVICIOS',
                [
                  if (reporte['costoEmpresa'] != null && reporte['costoEmpresa'].toString().isNotEmpty)
                    _buildRow('Servicio Empresa', '\$${reporte['costoEmpresa']}', isBold: true),
                  if (reporte['costoTecnico'] != null && reporte['costoTecnico'].toString().isNotEmpty)
                    _buildRow('Servicio Técnico', '\$${reporte['costoTecnico']}', isBold: true),
                ],
              ),
            // ── Sección Alquiler ───────────────────────────────────────────
            if (listaAlquileres.isNotEmpty)
              _buildSection(
                'CONTRATOS DE ALQUILER',
                listaAlquileres.map((alq) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Equipo', (alq['marcaModelo'] ?? '') as String),
                        _buildRow('Serial', (alq['serial'] ?? '') as String),
                        if ((alq['contadorInicial'] ?? '').toString().isNotEmpty)
                          _buildRow('Contador inicial', alq['contadorInicial'].toString()),
                        if (alq['valorMensual'] != null && alq['valorMensual'] != 0)
                          _buildRow('Valor mensual', '\$${alq['valorMensual']}', isBold: true),
                        if (alq['copiasIncluidas'] != null && alq['copiasIncluidas'] != 0)
                          _buildRow('Copias incl./mes', alq['copiasIncluidas'].toString()),
                        if (alq['valorCopiaExtra'] != null && alq['valorCopiaExtra'] != 0)
                          _buildRow('Copia extra', '\$${alq['valorCopiaExtra']}'),
                        if ((alq['fechaInicio'] ?? '').toString().isNotEmpty)
                          _buildRow('Inicio', (alq['fechaInicio'] ?? '') as String),
                        if (alq['duracionMeses'] != null && alq['duracionMeses'] != 0)
                          _buildRow('Duración', '${alq['duracionMeses']} meses'),
                        if ((alq['observaciones'] ?? '').toString().isNotEmpty)
                          _buildRow('Observaciones', (alq['observaciones'] ?? '') as String),
                      ],
                    ),
                  );
                }).toList(),
              ),
            // ── Sección Venta ──────────────────────────────────────────────
            if (listaVentas.isNotEmpty)
              _buildSection(
                'DETALLES DE VENTA',
                listaVentas.map((vnt) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildRow('Equipo', (vnt['marcaModelo'] ?? '') as String),
                        _buildRow('Serial', (vnt['serial'] ?? '') as String),
                        _buildRow('Estado', (vnt['estado'] ?? '') as String),
                        if (vnt['precio'] != null && vnt['precio'] != 0)
                          _buildRow('Precio', '\$${vnt['precio']}', isBold: true),
                        _buildRow('Forma de pago', (vnt['formaPago'] ?? '') as String),
                        if ((vnt['garantia'] ?? '').toString().isNotEmpty)
                          _buildRow('Garantía', (vnt['garantia'] ?? '') as String),
                        if ((vnt['accesorios'] ?? '').toString().isNotEmpty)
                          _buildRow('Accesorios', (vnt['accesorios'] ?? '') as String),
                      ],
                    ),
                  );
                }).toList(),
              ),
            if (!widget.isReadOnly) ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: _isApproving ? const SizedBox() : const Icon(Icons.cancel_outlined, color: Colors.white),
                        label: _isApproving
                            ? const SizedBox()
                            : const Text('RECHAZAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        onPressed: _isApproving ? null : _rechazarReporte,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: _isApproving ? const SizedBox() : const Icon(Icons.check_circle_outline, color: Colors.white),
                        label: _isApproving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('APROBAR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        onPressed: _isApproving ? null : _aprobarReporte,
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (widget.data['evaluacionCliente'] != null) ...[
              const SectionHeader(title: 'Su Calificación'),
              PremiumCard(
                accentColor: cAmarillo,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) => Icon(
                        index < (widget.data['evaluacionCliente']['estrellas'] ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: cAmarillo,
                        size: 32,
                      )),
                    ),
                    const SizedBox(height: 12),
                    Text(widget.data['evaluacionCliente']['comentario'] ?? 'Sin comentario', style: const TextStyle(fontSize: 14, color: cTextoOscuro)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.2)),
        ),
        PremiumCard(
          padding: const EdgeInsets.all(20),
          accentColor: cAzul.withValues(alpha: 0.1),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
       padding: const EdgeInsets.symmetric(vertical: 4),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
           Text(
             value, 
             style: TextStyle(
               color: cTextoOscuro, 
               fontSize: 14, 
               fontWeight: isBold ? FontWeight.w900 : FontWeight.bold
             )
           ),
         ],
       ),
    );
  }
}
