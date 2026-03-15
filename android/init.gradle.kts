allprojects {
    repositories.all {
        if (this is MavenArtifactRepository) {
            val originalUrl = this.url.toString()
            if (originalUrl.startsWith("https://github.com")) {
                this.setUrl(originalUrl.replace("https://github.com", "https://mirror.ghproxy.com/https://github.com"))
            }
            if (originalUrl.startsWith("https://raw.githubusercontent.com")) {
                this.setUrl(originalUrl.replace("https://raw.githubusercontent.com", "https://mirror.ghproxy.com/https://raw.githubusercontent.com"))
            }
        }
    }
}
