import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants.dart';
import '../../shared/widgets/premium_widgets.dart';
import 'visto_bueno_screen.dart';
import 'mapa_cliente_screen.dart';
import 'calificacion_screen.dart';

class ClienteScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ClienteScreen({super.key, required this.userData});

  @override
  State<ClienteScreen> createState() => _ClienteScreenState();
}

class _ClienteScreenState extends State<ClienteScreen> {
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final Set<String> _serviciosSel = {};
  late Stream<QuerySnapshot> _historialStream;

  @override
  void initState() {
    super.initState();
    _historialStream = FirebaseFirestore.instance
        .collection('trabajos')
        .where('clienteId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .orderBy('creadoEn', descending: true)
        .limit(10)
        .snapshots();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitud() async {
    if (_serviciosSel.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione al menos un tipo de servicio'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final servicios = _serviciosSel.toList();
    final desc = _descCtrl.text.trim();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapaClienteScreen(
          userData: widget.userData,
          servicios: servicios,
          descripcion: desc,
        ),
      ),
    );

    if (result == true) {
      _descCtrl.clear();
      setState(() => _serviciosSel.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BrandedAppBar(
        actions: [
          IconButton(
            icon: const Icon(
              Icons.power_settings_new_rounded,
              color: Colors.grey,
            ),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // WELCOME HEADER
            const Text(
              'PLATAFORMA DE SERVICIO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: cAzul,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hola, ${widget.userData['nombre'] ?? 'Cliente'}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: cTextoOscuro,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 32),

            // REQUEST CARD
            PremiumCard(
              accentColor: cFucsia,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.headset_mic_rounded, color: cFucsia, size: 20),
                        SizedBox(width: 10),
                        Text('SOLICITAR INTERVENCIÓN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: cTextoOscuro)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text('TIPO DE SERVICIO (puede seleccionar varios)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kCategorias.map((cat) {
                        final selected = _serviciosSel.contains(cat);
                        IconData ico = Icons.build_rounded;
                        if (cat.contains('Soporte')) { ico = Icons.headset_mic_rounded; }
                        else if (cat.contains('Impresora') || cat.contains('Fotocopiadora')) { ico = Icons.print_rounded; }
                        else if (cat.contains('Alquiler')) { ico = Icons.description_rounded; }
                        else if (cat.contains('Venta')) { ico = Icons.sell_rounded; }
                        else if (cat.contains('Reparacion') || cat.contains('Reparación')) { ico = Icons.handyman_rounded; }
                        return FilterChip(
                          avatar: Icon(ico, size: 16, color: selected ? Colors.white : cAzul),
                          label: Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : cTextoOscuro)),
                          selected: selected,
                          onSelected: (v) => setState(() {
                            if (v) { _serviciosSel.add(cat); }
                            else { _serviciosSel.remove(cat); }
                          }),
                          selectedColor: cAzul,
                          backgroundColor: cAzul.withValues(alpha: 0.07),
                          checkmarkColor: Colors.white,
                          side: BorderSide(color: selected ? cAzul : cAzul.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    const Text('DIAGNÓSTICO / DESCRIPCIÓN',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Describa el problema lo más detallado posible...',
                      ),
                      validator: (v) => (v == null || v.trim().length < 10) ? 'Detalle más el problema' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: cFucsia, foregroundColor: Colors.white),
                        onPressed: _enviarSolicitud,
                        icon: const Icon(Icons.location_searching_rounded),
                        label: const Text('CONTINUAR A UBICACIÓN', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SectionHeader(
              title: 'Historial de Requerimientos',
              subtitle: 'Sus últimas 10 solicitudes de servicio',
            ),

            // LIST OF REQUESTS
            StreamBuilder<QuerySnapshot>(
              stream: _historialStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error al cargar datos: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No hay solicitudes registradas.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final job = snapshot.data!.docs[index];
                    final data = job.data() as Map<String, dynamic>;
                    final String estado = data['estado'] ?? 'solicitado';
                    final bool isFinished =
                        estado == 'evaluado_cliente' ||
                        estado == 'cerrado' ||
                        estado == 'completado';

                    return PremiumCard(
                      accentColor: getColorEstado(estado),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: getColorEstado(
                                    estado,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  estado.toUpperCase().replaceAll('_', ' '),
                                  style: TextStyle(
                                    color: getColorEstado(estado),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                '#${job.id.substring(job.id.length - 6).toUpperCase()}',
                                style: TextStyle(
                                  color: Colors.grey.withValues(alpha: 0.4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            (() {
                              final rawServicios = data['servicios'];
                              if (rawServicios is List && rawServicios.isNotEmpty) {
                                return rawServicios.join(' · ');
                              }
                              return data['categoria'] ?? 'General';
                            })(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: cTextoOscuro,
                            ),
                          ),
                          if (data['direccionText'] != null &&
                              data['direccionText'].toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: cFucsia,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    data['direccionText'],
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: cTextoOscuro,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            data['descripcion'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Divider(height: 32),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor:
                                    (data['operarioNombre'] != null
                                            ? cAzul
                                            : Colors.grey)
                                        .withValues(alpha: 0.1),
                                child: Icon(
                                  Icons.engineering_rounded,
                                  size: 14,
                                  color: data['operarioNombre'] != null
                                      ? cAzul
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'ESPECIALISTA',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      data['operarioNombre'] ?? 'Asignando...',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: data['operarioNombre'] != null
                                            ? cTextoOscuro
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (estado == 'revision_cliente') ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cAzul,
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VistoBuenoScreen(
                                      data: data,
                                      jobId: job.id,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  'REVISAR Y APROBAR',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          if (isFinished && data['reporteTecnico'] != null) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: cAzul,
                                  side: const BorderSide(color: cAzul),
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VistoBuenoScreen(
                                      data: data,
                                      jobId: job.id,
                                      isReadOnly: true,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.description_outlined),
                                label: const Text(
                                  'VER REPORTE TÉCNICO',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],

                          if ((estado == 'completado' || estado == 'cerrado') &&
                              data['evaluacionCliente'] == null) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cAmarillo,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CalificacionScreen(
                                      data: data,
                                      jobId: job.id,
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.star_rate_rounded),
                                label: const Text(
                                  'CALIFICAR SERVICIO',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                              ),
                            ),
                          ],

                          if (data['pinCode'] != null &&
                              (estado == 'solicitado' ||
                                  estado == 'asignado' ||
                                  estado == 'en_camino')) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEFCE8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFEF08A),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'CÓDIGO PIN',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF854D0E),
                                        ),
                                      ),
                                      Text(
                                        data['pinCode'],
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: cTextoOscuro,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.security_rounded,
                                    color: Color(0xFFCA8A04),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
