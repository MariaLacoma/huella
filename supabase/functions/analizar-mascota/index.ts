
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function normalizarRuta(ruta: string): string {
  return ruta.startsWith("fotos-mascotas/")
    ? ruta.substring("fotos-mascotas/".length)
    : ruta;
}

function normalizarTexto(valor: unknown): string {
  return String(valor ?? "")
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
}

function calcularSimilitud(
  analisis: Record<string, unknown>,
  candidata: Record<string, unknown>,
): number {
  let puntos = 0;
  let maximo = 0;

  const comparar = (
    campoAnalisis: string,
    campoPublicacion: string,
    peso: number,
  ) => {
    const valorAnalisis = normalizarTexto(analisis[campoAnalisis]);
    const valorPublicacion = normalizarTexto(candidata[campoPublicacion]);

    if (
      !valorAnalisis ||
      !valorPublicacion ||
      valorAnalisis === "no identificable" ||
      valorPublicacion === "no identificable"
    ) {
      return;
    }

    maximo += peso;

    if (valorAnalisis === valorPublicacion) {
      puntos += peso;
    } else if (
      valorAnalisis.includes(valorPublicacion) ||
      valorPublicacion.includes(valorAnalisis)
    ) {
      puntos += peso * 0.5;
    }
  };

  comparar("especie", "especie", 30);
  comparar("colores", "color", 20);
  comparar("tamano", "tamano", 10);
  comparar("raza_probable", "raza", 10);
  comparar("caracteristicas", "caracteristicas", 30);

  if (maximo === 0) return 0;

  return Math.round((puntos / maximo) * 100);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Comprobar el token de autenticación.
    const authorization = req.headers.get("Authorization");

    if (!authorization || !authorization.startsWith("Bearer ")) {
      return Response.json(
        { error: "Debés iniciar sesión para utilizar esta función." },
        { status: 401, headers: corsHeaders },
      );
    }

    const token = authorization.replace(/^Bearer\s+/i, "");

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
    const serviceRoleKey = Deno.env.get("SERVICE_ROLE_KEY");

    if (!supabaseUrl || !supabaseAnonKey || !serviceRoleKey) {
      throw new Error("Falta configurar una variable de entorno de Supabase.");
    }

    // 2. Crear el cliente con el token del usuario.
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: {
          Authorization: `Bearer ${token}`,
        },
      },
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    // 3. Verificar la identidad.
    const {
      data: { user },
      error: errorAuth,
    } = await supabase.auth.getUser(token);

    if (errorAuth || !user) {
      return Response.json(
        { error: "La sesión no es válida. Iniciá sesión nuevamente." },
        { status: 401, headers: corsHeaders },
      );
    }

    // 4. Verificar el perfil de HUELLA.
    const { data: perfil, error: errorPerfil } = await supabase
      .from("usuario")
      .select("tipo, estado")
      .eq("auth_user_id", user.id)
      .maybeSingle();

    if (errorPerfil || !perfil) {
      console.error("No se pudo verificar el perfil:", errorPerfil);

      return Response.json(
        { error: "No se pudo verificar tu perfil de HUELLA." },
        { status: 403, headers: corsHeaders },
      );
    }

    // 5. Permitir solamente usuarios activos.
    if (perfil.tipo !== "usuario" || perfil.estado !== "activo") {
      return Response.json(
        { error: "No tenés permisos para utilizar el análisis de IA." },
        { status: 403, headers: corsHeaders },
      );
    }

    // 6. Recibir y validar los datos.
    const { idPublicacion, rutaFoto } = await req.json();

    if (
      !Number.isInteger(idPublicacion) ||
      idPublicacion <= 0
    ) {
      return Response.json(
        { error: "El identificador de la publicación no es válido." },
        { status: 400, headers: corsHeaders },
      );
    }

    if (
      !rutaFoto ||
      typeof rutaFoto !== "string" ||
      rutaFoto.trim() === ""
    ) {
      return Response.json(
        { error: "No se recibió la ruta de la fotografía." },
        { status: 400, headers: corsHeaders },
      );
    }

    const rutaNormalizada = normalizarRuta(rutaFoto.trim());
    const partesRuta = rutaNormalizada.split("/");

    if (
      rutaNormalizada.startsWith("/") ||
      partesRuta.some(
        (parte: string) =>
          !parte || parte === "." || parte === "..",
      )
    ) {
      return Response.json(
        { error: "La ruta de la fotografía no es válida." },
        { status: 400, headers: corsHeaders },
      );
    }

    // 7. Crear el cliente de administración.
    // Esta clave se utiliza únicamente dentro de la Edge Function.
    const supabaseAdmin = createClient(
      supabaseUrl,
      serviceRoleKey,
      {
        auth: {
          persistSession: false,
          autoRefreshToken: false,
        },
      },
    );

    // 8. Verificar que la fotografía pertenezca a la publicación indicada.
    const { data: publicacion, error: errorPublicacion } =
      await supabaseAdmin
        .from("publicacion")
       .select(`
  id_publicacion,
  tipo,
  especie,
  sexo,
  estado,
  tamano,
  edad,
  color,
  raza,
  caracteristicas,
  foto,
  latitud,
  longitud
`)
        .eq("id_publicacion", idPublicacion)
        .maybeSingle();

    if (errorPublicacion || !publicacion) {
      console.error("Error al consultar la publicación:", errorPublicacion);

      return Response.json(
        { error: "No se encontró la publicación." },
        { status: 404, headers: corsHeaders },
      );
    }

    const rutaPublicacion = normalizarRuta(
      publicacion.foto?.toString() ?? "",
    );

    if (!rutaPublicacion || rutaPublicacion !== rutaNormalizada) {
      return Response.json(
        { error: "La fotografía no corresponde a esa publicación." },
        { status: 400, headers: corsHeaders },
      );
    }

    if (publicacion.tipo !== "Perdida" && publicacion.tipo !== "Encontrada") {
  return Response.json(
    { error: "El tipo de publicación no es válido." },
    { status: 400, headers: corsHeaders },
  );
}

      // 9. Buscar un análisis anterior de esa publicación.
    const { data: analisisGuardado, error: errorConsulta } =
      await supabaseAdmin
        .from("analisis_mascota")
        .select("ruta_foto, resultado")
        .eq("id_publicacion", idPublicacion)
        .maybeSingle();

    if (errorConsulta) {
      console.error("Error al consultar el análisis:", errorConsulta);
      throw new Error("No se pudo consultar el análisis guardado.");
    }

    // 10. Preparar el análisis, reutilizado o nuevo.
    let analisis: Record<string, unknown> = {};
    let reutilizado = false;

    if (
      analisisGuardado &&
      analisisGuardado.ruta_foto === rutaNormalizada
    ) {
      if (
        !analisisGuardado.resultado ||
        typeof analisisGuardado.resultado !== "object" ||
        Array.isArray(analisisGuardado.resultado)
      ) {
        throw new Error("El análisis guardado no tiene un formato válido.");
      }

      analisis = analisisGuardado.resultado as Record<string, unknown>;
      reutilizado = true;
    }

    // 11. Si no hay un análisis anterior, analizar la fotografía.
    if (!reutilizado) {
      const apiKey = Deno.env.get("OPENAI_API_KEY");

      if (!apiKey) {
        throw new Error("Falta configurar la clave de OpenAI.");
      }

      // 12. Construir la URL pública de la fotografía.
      const rutaCodificada = rutaNormalizada
        .split("/")
        .map((parte: string) => encodeURIComponent(parte))
        .join("/");

      const imagenUrl =
        `${supabaseUrl}/storage/v1/object/public/fotos-mascotas/${rutaCodificada}`;

      // 13. Analizar la fotografía con OpenAI.
      const respuestaOpenAI = await fetch(
        "https://api.openai.com/v1/responses",
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${apiKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            model: "gpt-4.1-mini",
            input: [
              {
                role: "user",
                content: [
                  {
                    type: "input_text",
                    text: `Analizá la fotografía de esta mascota.
Devolvé únicamente un JSON válido con estos campos:
especie, colores, tamano, caracteristicas y raza_probable.
Si no podés determinar algún dato, indicá "No identificable".
No inventes características que no se vean en la imagen.`,
                  },
                  {
                    type: "input_image",
                    image_url: imagenUrl,
                  },
                ],
              },
            ],
            max_output_tokens: 300,
          }),
        },
      );

      const datosOpenAI = await respuestaOpenAI.json();

      if (!respuestaOpenAI.ok) {
        console.error("Error de OpenAI:", datosOpenAI);
        throw new Error("No se pudo analizar la fotografía.");
      }

      const texto = datosOpenAI.output
        ?.flatMap((elemento: any) => elemento.content ?? [])
        .find(
          (contenido: any) => contenido.type === "output_text",
        )?.text;

      if (!texto) {
        throw new Error("OpenAI no devolvió un análisis.");
      }

      try {
        analisis = JSON.parse(texto);
      } catch {
        throw new Error(
          "La respuesta de OpenAI no tiene formato JSON válido.",
        );
      }

      // 14. Guardar el resultado en Supabase.
      const { error: errorGuardado } = await supabaseAdmin
        .from("analisis_mascota")
        .upsert(
          {
            id_publicacion: idPublicacion,
            ruta_foto: rutaNormalizada,
            resultado: analisis,
          },
          {
            onConflict: "id_publicacion",
          },
        );

      if (errorGuardado) {
        console.error("Error al guardar el análisis:", errorGuardado);
        throw new Error("No se pudo guardar el análisis.");
      }
    }

    // 15. Determinar qué tipo de publicación buscar.
const tipoBuscado =
  publicacion.tipo === "Perdida" ? "Encontrada" : "Perdida";

// 16. Buscar publicaciones activas del tipo contrario.
const { data: candidatas, error: errorCoincidencias } =
  await supabaseAdmin
    .from("publicacion")
    .select(`
      id_publicacion,
      tipo,
      nombre,
      especie,
      sexo,
      descripcion,
      fecha,
      foto,
      latitud,
      longitud,
      tamano,
      edad,
      color,
      raza,
      caracteristicas
    `)
    .eq("tipo", tipoBuscado)
    .eq("estado", "activa")
    .neq("id_publicacion", idPublicacion);

if (errorCoincidencias) {
  console.error("Error al buscar coincidencias:", errorCoincidencias);
  throw new Error("No se pudieron buscar coincidencias.");
}

// 17. Calcular la similitud de cada publicación.
const coincidencias = (candidatas ?? [])
  .map((candidata) => {
    const especieAnalizada = normalizarTexto(analisis.especie);
    const especieCandidata = normalizarTexto(candidata.especie);

    const especiesDistintas =
      especieAnalizada !== "" &&
      especieCandidata !== "" &&
      especieAnalizada !== "no identificable" &&
      especieCandidata !== "no identificable" &&
      especieAnalizada !== especieCandidata;

    return {
      ...candidata,
      similitud: especiesDistintas
        ? 0
        : calcularSimilitud(analisis, candidata),
    };
  })
  .filter((candidata) => candidata.similitud >= 40)
  .sort((a, b) => b.similitud - a.similitud)
  .slice(0, 10);

    
   // 18. Devolver el análisis y las coincidencias encontradas.
return Response.json(
  {
    mensaje: reutilizado
      ? "Se recuperó el análisis guardado."
      : "Fotografía analizada correctamente.",
    reutilizado,
    analisis,
    coincidencias,
  },
  { headers: corsHeaders },
);

  } catch (error) {
    console.error("Error al analizar la mascota:", error);

    return Response.json(
      { error: "No se pudo analizar la fotografía." },
      { status: 500, headers: corsHeaders },
    );
  }
});